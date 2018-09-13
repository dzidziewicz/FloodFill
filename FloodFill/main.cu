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
	int c[15] = { 2, 3, 4, 5, 6, 7, 8 , 9, 10, 11, 12, 13, 14, 15, 16 };
	int r[18] = { 0, 0, 3, 6, 13, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15 };
	int queueIn[10] = { 2, 3, 4, -1, -1, -1, -1, -1, -1, -1 };
	int queueOut[12] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
	int neighboursPrefixSum[12] = { 3, 7, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
	int visited[17];
	int totalNeighbours;
	int neighbourCounts[17];

	for (int i = 0; i < 17; i++)
		visited[i] = 0;


	thrust::exclusive_scan(neighboursPrefixSum, neighboursPrefixSum + 12, neighboursPrefixSum);
	totalNeighbours = neighboursPrefixSum[11];
	printf("%d\n", totalNeighbours);


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
	cudaStatus = deviceMalloc(&dev_c, 15);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_c, c, 15, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_r, 18);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_r, r, 18, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_queueIn, 10);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_queueIn, queueIn, 10, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_queueOut, 12);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_queueOut, queueOut, 12, cudaMemcpyHostToDevice);
	if (cudaStatus != cudaSuccess) goto Error;

	cudaStatus = deviceMalloc(&dev_neighboursPrefixSum, 12);
	if (cudaStatus != cudaSuccess) goto Error;
	cudaStatus = deviceMemcpy(dev_neighboursPrefixSum, neighboursPrefixSum, 12, cudaMemcpyHostToDevice);
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



	gatherScan << <1, THREAD_NUM >> > (dev_queueIn, dev_queueOut, dev_c, dev_r, 
		dev_neighboursPrefixSum, dev_visited, dev_totalNeighbours, dev_neighbourCounts);
	
	cudaStatus = cudaDeviceSynchronize();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching scatterKernel!\n", cudaStatus);
		goto Error;
	}
	cudaStatus = cudaGetLastError();
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "calculateBackwardMask launch failed: %s\n", cudaGetErrorString(cudaStatus));
		goto Error;
	}

	cudaStatus = deviceMemcpy(queueOut, dev_queueOut, 12, cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess)
	{
		fprintf(stderr, "calculateBackwardMask launch failed: %s\n", cudaGetErrorString(cudaStatus));
		goto Error;
	}

	for (int i = 0; i < 12; i++)
		printf("%d ", queueOut[i]);
Error:
	cudaFree(dev_c);
}