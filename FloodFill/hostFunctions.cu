
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

int getEdgesCount(int rows, int cols)
{
	return 4 * (rows - 2) * (cols - 2) + 3 * 2 * (rows - 2) + 3 * 2 * (cols - 2) + 8;
}

void prepareArrays(int* inputArr, int** R, int** C, int rows, int cols)
{
	int verticesCount = rows * cols;
	*R = (int*)malloc((verticesCount + 1) * sizeof(int));
	int edgesCount = getEdgesCount(rows, cols);

	*C = (int*)malloc(edgesCount * sizeof(int));

	for (int i = 0, v = 0; i < edgesCount; v++)
	{
		int x = v % cols;
		int y = v / cols;

		if (x == 0 && y == 0)
		{
			(*C)[i++] = v + 1;
			(*C)[i++] = v + cols;
			(*R)[v] = 2;
		}
		else if (x == 0 && y == rows - 1)
		{
			(*C)[i++] = v + 1;
			(*C)[i++] = v - cols;
			(*R)[v] = 2;
		}
		else if (x == cols - 1 && y == 0)
		{
			(*C)[i++] = v - 1;
			(*C)[i++] = v + cols;
			(*R)[v] = 2;
		}
		else if (x == cols - 1 && y == rows - 1)
		{
			(*C)[i++] = v - 1;
			(*C)[i++] = v - cols;
			(*R)[v] = 2;
		}
		else if (x == 0)
		{
			(*C)[i++] = v + 1;
			(*C)[i++] = v + cols;
			(*C)[i++] = v - cols;
			(*R)[v] = 3;
		}
		else if (x == cols - 1)
		{
			(*C)[i++] = v - 1;
			(*C)[i++] = v + cols;
			(*C)[i++] = v - cols;
			(*R)[v] = 3;
		}
		else if (y == 0)
		{
			(*C)[i++] = v - 1;
			(*C)[i++] = v + 1;
			(*C)[i++] = v + cols;
			(*R)[v] = 3;
		}
		else if (y == rows - 1)
		{
			(*C)[i++] = v - 1;
			(*C)[i++] = v + 1;
			(*C)[i++] = v - cols;
			(*R)[v] = 3;
		}
		else
		{
			(*C)[i++] = v - 1;
			(*C)[i++] = v + 1;
			(*C)[i++] = v + cols;
			(*C)[i++] = v - cols;
			(*R)[v] = 4;
		}

	}
	(*R)[verticesCount] = 0;
	thrust::exclusive_scan((*R), (*R) + verticesCount + 1, (*R));
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