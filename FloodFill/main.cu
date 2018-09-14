#include "floodFillWithCpu.h"
#include "hostFunctions.h"
#include "deviceFunctions.h"

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <thrust/scan.h>

#include <stdlib.h>
#include <stdio.h>
using namespace std;
void FloodFillWithGPU();

int main()
{
	int height = 1;
	int width = 5;

	//int** array = new int*[height];
	//for (int i = 0; i < height; i++)
	//{
	//	array[i] = new int[width];
	//	for (int j = 0; j < width; j++)
	//		array[i][j] = 0;
	//}
	//array[0][3] = 4;
	////floodFillWithCpu(array, height, width, 3, 2, 1);

	//bfs(array, height, width, 0, 0, 1);

	//for (int i = 0; i < height; i++)
	//{
	//	for (int j = 0; j < width; j++)
	//		cout << array[i][j] << " ";
	//	cout << endl;
	//}
	FloodFillWithGPU();
}

void FloodFillWithGPU()
{
	//int* c = (int*)malloc(sizeof(int) * 15);
	int verticesCount = 16;
	int c[16] = { 2, 3, 4, 5, 6, 7, 8 , 9, 10, 11, 12, 13, 14, 15, 16, 11 };
	int r[18] = { 0, 0, 3, 6, 13, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16 };
	int queueIn[13] = { 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 };
	int queueOut[13] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
	int neighboursPrefixSum[17] = { 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
	int visited[17];
	int totalNeighbours;
	int neighbourCounts[17];

	for (int i = 0; i < 17; i++)
		visited[i] = 0;


	thrust::exclusive_scan(neighboursPrefixSum, neighboursPrefixSum + 17, neighboursPrefixSum);
	totalNeighbours = neighboursPrefixSum[16];
	printf("total neighbours count: %d\n", totalNeighbours);


	//device arrays
	int* dev_verticesCount;
	int* dev_c = 0;
	int* dev_r;
	int* dev_queueIn;
	int* dev_queueOut;
	int* dev_neighboursPrefixSum;
	int* dev_visited = 0;
	int* dev_totalNeighbours;
	int* dev_neighbourCounts;

	cudaError_t cudaStatus;

#pragma region Mallocs
	cudaStatus = deviceMalloc(&dev_c, 16);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_c, c, 16, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_r, 18);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_r, r, 18, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_queueIn, 13);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_queueIn, queueIn, 13, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_queueOut, 13);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_queueOut, queueOut, 13, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_neighboursPrefixSum, 17);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_neighboursPrefixSum, neighboursPrefixSum, 17, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_visited, 17);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_visited, visited, 17, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_totalNeighbours, 1);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_totalNeighbours, &totalNeighbours, 1, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_neighbourCounts, 17);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_neighbourCounts, neighbourCounts, 17, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

#pragma endregion

	int i = 3;
	while (totalNeighbours > 0)
	{
		gatherScan << <1, THREAD_NUM >> > (dev_queueIn, dev_queueOut, dev_c, dev_r,
			dev_neighboursPrefixSum, dev_visited, dev_totalNeighbours, dev_neighbourCounts);

		cudaStatus = cudaDeviceSynchronize();
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching gatherScan!\n", cudaStatus);
			goto Error;
		}
		cudaStatus = cudaGetLastError();
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "gatherScan launch failed: %s\n", cudaGetErrorString(cudaStatus));
			//goto Error;
		}

		cudaStatus = deviceMemcpy(queueOut, dev_queueOut, 13, cudaMemcpyDeviceToHost);
		if (cudaStatus != cudaSuccess)
		{
			fprintf(stderr, "gueueOut dev to host memcpy failed: %s\n", cudaGetErrorString(cudaStatus));
			goto Error;
		}

		for (int i = 0; i < 12; i++)
			printf("%d ", queueOut[i]);

		printf("\n");

		cudaStatus = deviceMemcpy(dev_queueIn, dev_queueOut, 13, cudaMemcpyDeviceToDevice);
		cudaStatus = deviceMemcpy(neighboursPrefixSum, dev_neighbourCounts, 17, cudaMemcpyDeviceToHost);

		printf("neighbour counts befere scan");
		for (int i = 0; i < 17; i++)
			printf("%d ", neighboursPrefixSum[i]);

		printf("\n");
		thrust::exclusive_scan(neighboursPrefixSum, neighboursPrefixSum + totalNeighbours + 1, neighboursPrefixSum);
		totalNeighbours = neighboursPrefixSum[totalNeighbours];

		printf("neighbour counts befere scan");
		for (int i = 0; i < 17; i++)
			printf("%d ", neighboursPrefixSum[i]);

		printf("\n"); printf("total neighbours count: %d\n", totalNeighbours);

		cudaStatus = deviceMemcpy(dev_neighboursPrefixSum, neighboursPrefixSum, 17, cudaMemcpyHostToDevice);
		cudaStatus = deviceMemcpy(dev_totalNeighbours, &totalNeighbours, 1, cudaMemcpyHostToDevice);

	Error:
		cudaFree(dev_c);
	}
}