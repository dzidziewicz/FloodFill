#include "floodFillWithCpu.h"
#include "hostFunctions.h"
#include "deviceFunctions.h"

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <thrust/scan.h>

#include <stdlib.h>
#include <stdio.h>
using namespace std;
int* FloodFillWithGPU(int* arr, int rows, int cols, int xStarting, int yStarting, int newColor);

int main()
{
	int xStarting = 0, yStarting = 1;
	int newColor = 2;

	int arr1[9] = {		0, 0, 1,
						0, 0, 0,
						0, 0, 0 };

	int arr2[9] ={	0, 0, 1,
					0, 1, 1,
					0, 1, 0 };

	int arr3[36] = {	0, 0, 1, 0, 0, 0,
						0, 0, 0, 1, 0, 0,
						0, 0, 5, 5, 3, 0, 
						0, 0, 5, 5, 3, 0,
						0, 1, 5, 5, 0, 0,
						0, 1, 0, 0, 0, 0 };

	int arr4[36] = {	0, 0, 0, 0, 0, 0,
						0, 1, 1, 1, 1, 0,
						0, 1, 0, 0, 3, 0,
						0, 0, 3, 0, 3, 2,
						0, 0, 1, 1, 0, 0,
						0, 0, 0, 0, 0, 0,	};

	int testRows[4] = { 3, 3, 6, 6 };
	int testCols[4] = { 3, 3, 6, 6 };
	int* testArrays[4] = { arr1, arr2, arr3, arr4 };

	for (int i = 0; i < 4; i++)
	{
		int rows = testRows[i], cols = testCols[i];
		int* arr = testArrays[i];

		printf("Starting point: (0, 1)\n");
		printf("New color: 1 \n");
		printf("\n");
		printf("Array before filling: \n");

		for (int i = 0, v = 0; i < rows; i++)
		{
			for (int j = 0; j < cols; j++)
				printf("%d ", arr[v++]);
			printf("\n");
		}
		
		int* coloured = FloodFillWithGPU(arr, rows, cols, xStarting, yStarting, newColor);

		printf("Array after filling: \n");

		for (int i = 0, v = 0; i < rows; i++)
		{
			for (int j = 0; j < cols; j++)
				printf("%d ", coloured[v++]);
			printf("\n");
		}
		printf("\n");
		printf("***********************************\n");
		printf("\n");

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

	}
}

int* FloodFillWithGPU(int* arr, int rows, int cols, int xStarting, int yStarting, int newColor)
{
	int* r;
	int* c;
	int startingVertex = yStarting * cols + xStarting;
	int startingColor = arr[startingVertex];
	int edgesCount = getEdgesCount(rows, cols);
	int verticesCount = rows * cols;

	prepareArrays(arr, &r, &c, rows, cols);

	//int c[16] = { 2, 3, 4, 5, 6, 7, 8 , 9, 10, 11, 12, 13, 14, 15, 16, 11 };
	//int r[18] = { 0, 0, 3, 6, 13, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16 };
	int* queueIn = (int*)malloc(THREAD_NUM * sizeof(int));// = { 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 };
	int* queueOut = (int*)malloc(THREAD_NUM * sizeof(int));// = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
	int* neighboursPrefixSum = (int*)malloc(THREAD_NUM * sizeof(int));// = { 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
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
	//printf("total neighbours count: %d\n", totalNeighbours);

	cudaError_t cudaStatus;

#pragma region Device arrays

	int* dev_verticesCount;
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
			//goto Error;
		}

		cudaStatus = deviceMemcpy(queueOut, dev_queueOut, THREAD_NUM, cudaMemcpyDeviceToHost);
		if (cudaStatus != cudaSuccess)
		{
			fprintf(stderr, "gueueOut dev to host memcpy failed: %s\n", cudaGetErrorString(cudaStatus));
			goto Error;
		}

		/*for (int i = 0; i < THREAD_NUM; i++)
			printf("%d ", queueOut[i]);

		printf("\n");*/

		cudaStatus = deviceMemcpy(dev_queueIn, dev_queueOut, THREAD_NUM, cudaMemcpyDeviceToDevice);
		cudaStatus = deviceMemcpy(neighboursPrefixSum, dev_neighbourCounts, THREAD_NUM, cudaMemcpyDeviceToHost);

		/*printf("neighbour counts befere scan \n");
		for (int i = 0; i < THREAD_NUM; i++)
			printf("%d ", neighboursPrefixSum[i]);

		printf("\n");*/
		thrust::exclusive_scan(neighboursPrefixSum, neighboursPrefixSum + totalNeighbours + 1, neighboursPrefixSum);
		totalNeighbours = neighboursPrefixSum[totalNeighbours];

		/*printf("neighbour counts after scan \n");
		for (int i = 0; i < THREAD_NUM; i++)
			printf("%d ", neighboursPrefixSum[i]);

		printf("\n"); printf("total neighbours count: %d\n", totalNeighbours);
		printf("\n");
		printf("\n");*/

		cudaStatus = deviceMemcpy(dev_neighboursPrefixSum, neighboursPrefixSum, THREAD_NUM, cudaMemcpyHostToDevice);
		cudaStatus = deviceMemcpy(dev_totalNeighbours, &totalNeighbours, 1, cudaMemcpyHostToDevice);
	
	}
Error:
		cudaFree(dev_c);
	cudaStatus = deviceMemcpy(visited, dev_visited, verticesCount, cudaMemcpyDeviceToHost);

	return visited;
}