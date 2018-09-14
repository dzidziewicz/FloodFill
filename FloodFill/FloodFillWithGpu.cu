#include "floodFillWithCpu.h"
#include "hostFunctions.h"
#include "deviceFunctions.h"
#include "floodFillWithGpu.h"

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <thrust/scan.h>


int* FloodFillWithGPU(int* arr, int rows, int cols, int xStarting, int yStarting, int newColor)
{
	int* r;
	int* c;
	int startingVertex = yStarting * cols + xStarting;
	int startingColor = arr[startingVertex];
	int edgesCount = getEdgesCount(rows, cols);
	int verticesCount = rows * cols;

	prepareArrays(arr, &r, &c, rows, cols);

	int* queueIn = (int*)malloc(THREAD_NUM * sizeof(int));
	int* queueOut = (int*)malloc(THREAD_NUM * sizeof(int));
	int* neighboursPrefixSum = (int*)malloc(THREAD_NUM * sizeof(int));
	int* visited = (int*)malloc(rows * cols * sizeof(int));
	int totalNeighbours;
	int* neighbourCounts = (int*)malloc(THREAD_NUM * sizeof(int));

	for (int i = 0; i < THREAD_NUM; i++)
	{
		queueIn[i] = -1;
		queueOut[i] = 0;
		neighboursPrefixSum[i] = 0;
	}
	queueIn[0] = startingVertex;
	neighboursPrefixSum[0] = r[startingVertex + 1] - r[startingVertex];

	for (int i = 0; i < rows * cols; i++)
		visited[i] = arr[i];


	thrust::exclusive_scan(neighboursPrefixSum, neighboursPrefixSum + THREAD_NUM, neighboursPrefixSum);
	totalNeighbours = neighboursPrefixSum[THREAD_NUM - 1];

	cudaError_t cudaStatus;

#pragma region Device arrays

	int* dev_c = 0;
	int* dev_r;
	int* dev_queueIn;
	int* dev_queueOut;
	int* dev_neighboursPrefixSum;
	int* dev_visited = 0;
	int* dev_totalNeighbours;
	int* dev_neighbourCounts;

#pragma endregion

#pragma region Mallocs
	cudaStatus = deviceMalloc(&dev_c, edgesCount);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_c, c, edgesCount, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_r, (verticesCount + 1));
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_r, r, (verticesCount + 1), cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_queueIn, THREAD_NUM);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_queueIn, queueIn, THREAD_NUM, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_queueOut, THREAD_NUM);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_queueOut, queueOut, THREAD_NUM, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_neighboursPrefixSum, THREAD_NUM);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_neighboursPrefixSum, neighboursPrefixSum, THREAD_NUM, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_visited, verticesCount);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_visited, visited, verticesCount, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_totalNeighbours, 1);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_totalNeighbours, &totalNeighbours, 1, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_neighbourCounts, THREAD_NUM);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_neighbourCounts, neighbourCounts, THREAD_NUM, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

#pragma endregion

	while (totalNeighbours > 0)
	{
		gatherScan << <1, THREAD_NUM >> > (dev_queueIn, dev_queueOut, dev_c, dev_r,
			dev_neighboursPrefixSum, dev_visited, dev_totalNeighbours, dev_neighbourCounts, newColor, startingColor);

		cudaStatus = cudaDeviceSynchronize();
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching gatherScan!\n", cudaStatus);
			goto Error;
		}
		cudaStatus = cudaGetLastError();
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "gatherScan launch failed: %s\n", cudaGetErrorString(cudaStatus));
			goto Error;
		}

		cudaStatus = deviceMemcpy(queueOut, dev_queueOut, THREAD_NUM, cudaMemcpyDeviceToHost);
		if (cudaStatus != cudaSuccess)
		{
			fprintf(stderr, "gueueOut dev to host memcpy failed: %s\n", cudaGetErrorString(cudaStatus));
			goto Error;
		}

		cudaStatus = deviceMemcpy(dev_queueIn, dev_queueOut, THREAD_NUM, cudaMemcpyDeviceToDevice);
		cudaStatus = deviceMemcpy(neighboursPrefixSum, dev_neighbourCounts, THREAD_NUM, cudaMemcpyDeviceToHost);

		thrust::exclusive_scan(neighboursPrefixSum, neighboursPrefixSum + totalNeighbours + 1, neighboursPrefixSum);
		totalNeighbours = neighboursPrefixSum[totalNeighbours];

		cudaStatus = deviceMemcpy(dev_neighboursPrefixSum, neighboursPrefixSum, THREAD_NUM, cudaMemcpyHostToDevice);
		cudaStatus = deviceMemcpy(dev_totalNeighbours, &totalNeighbours, 1, cudaMemcpyHostToDevice);

	}
	cudaStatus = deviceMemcpy(visited, dev_visited, verticesCount, cudaMemcpyDeviceToHost);

Error:
	/*cudaFree(dev_c); dfdfv
	cudaFree(dev_r);
	cudaFree(dev_queueIn);
	cudaFree(dev_queueOut);
	cudaFree(dev_neighboursPrefixSum);
	cudaFree(dev_visited);
	cudaFree(dev_totalNeighbours);
	cudaFree(dev_neighbourCounts);*/ 

	return visited;
}