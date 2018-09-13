
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <thrust/scan.h>

#include <stdio.h>
#include <stdlib.h>

#include "hostFunctions.h"

void bfs(int** array, int height, int width, int xStarting, int yStarting, int newColor)
{
	int verticesCount = height * width;
	int oldColor = array[yStarting][xStarting];

	int* rowRangeOffsets = (int*)malloc((verticesCount + 1) * sizeof(int));
	int* neighboursCounts = (int*)malloc(verticesCount * sizeof(int));
	int v = 0;

	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++, v++)
		{
			int nei = 0; // neighbours count
			if (array[y][x] == oldColor)
			{
				if (y > 0 && array[y - 1][x] == oldColor) nei++;
				if (y < height - 1 && array[y + 1][x] == oldColor) nei++;
				if (x > 0 && array[y][x - 1] == oldColor) nei++;
				if (x < width - 1 && array[y][x + 1] == oldColor) nei++;
			}
			neighboursCounts[v] = nei;
		}
	}
	rowRangeOffsets[0] = 0;
	thrust::inclusive_scan(neighboursCounts, neighboursCounts + verticesCount, rowRangeOffsets + 1);
	/*for (int i = 0; i <= verticesCount; i++)
		printf("%d ", rowRangeOffsets[i]);
	printf("\n");*/
	int* columnIndices = (int*)malloc(rowRangeOffsets[verticesCount] * sizeof(int));

	// construct array C with neighbours of every vertex
	for (int y = 0, index = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++, v++)
		{
			if (array[y][x] == oldColor)
			{
				if (y > 0 && array[y - 1][x] == oldColor) columnIndices[index++] = v;
				if (y < height - 1 && array[y + 1][x] == oldColor) columnIndices[index++] = v;
				if (x > 0 && array[y][x - 1] == oldColor) columnIndices[index++] = v;;
				if (x < width - 1 && array[y][x + 1] == oldColor) columnIndices[index++] = v;
			}
		}
	}

}


cudaError_t deviceMalloc(int** dest, int length)
{
	cudaError_t cudaStatus = cudaMalloc((void**)dest, length * sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!\n");
	}
	return cudaStatus;
}

cudaError_t deviceMemcpy(int* dest, int* source, int length, cudaMemcpyKind direction)
{
	cudaError_t cudaStatus = cudaMemcpy(dest, source, length * sizeof(int), direction);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!\n");
	}
	return cudaStatus;
}

//int main()
//{
//
//	cudaError_t cudaStatus;// = addWithCuda(c, a, b, arraySize);
//	if (cudaStatus != cudaSuccess) {
//		fprintf(stderr, "addWithCuda failed!");
//		return 1;
//	}
//	
//
//	// cudaDeviceReset must be called before exiting in order for profiling and
//	// tracing tools such as Nsight and Visual Profiler to show complete traces.
//	cudaStatus = cudaDeviceReset();
//	if (cudaStatus != cudaSuccess) {
//		fprintf(stderr, "cudaDeviceReset failed!");
//		return 1;
//	}
//
//	return 0;
//}