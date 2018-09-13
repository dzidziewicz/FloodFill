#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <device_functions.h>
#include "deviceFunctions.h"

__global__ void GatherScan(int* queueIn, int*queueOut, int* C, int* rArr,
	int* rEndArray, int* neighboursPrefixSum,
	bool* visited, int totalNeighbours)
{
	__shared__ int neighbours[THREAD_NUM];

	int v = queueIn[threadIdx.x];
	int r = rArr[v];					// index of first v's neighbour from C array
	int rEnd = rEndArray[v];			// index of last v's neighbour from C array
	int index = neighboursPrefixSum[v];

	visited[v] = true;
	int blockProgress = 0;
	int remain;
	while ((remain = totalNeighbours - blockProgress) > 0)
	{
		// put vertex v's neighbours to shared memory
		while ((index < blockProgress + THREAD_NUM)
			&& (r < rEnd))
		{
			neighbours[index - blockProgress] = r; // r shows where current v's neighbour is in C array
			index++;
			r++;
		}
		__syncthreads();
		// each thread gets a vertex from shared memory
		if (threadIdx.x < remain && threadIdx.x < THREAD_NUM) {
			queueOut[blockProgress + threadIdx.x] = C[neighbours[threadIdx.x]];
		}
		blockProgress += THREAD_NUM;
		__syncthreads();
	}
}