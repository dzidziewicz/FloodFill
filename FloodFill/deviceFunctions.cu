#pragma once

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "deviceFunctions.h"

__global__ void gatherScan(int* queueIn, int*queueOut, int* C, int* R,
	int* neighboursPrefixSum,
	int* visited, int* totalNeighbours,
	int* neighbourCountsOut, int newColor, int startingColor)
{
	__shared__ int neighbours[THREAD_NUM];

	if (*totalNeighbours == 1 && threadIdx.x > 0)
	{
		//neighbours[0] = 1;
	}

	int v = queueIn[threadIdx.x];
	int r, rEnd, index;
	if (v != -1)
	{
		r = R[v];// rArrIn[v];					// index of first v's neighbour from C array
		rEnd = R[v + 1];// rEndArrayIn[v];			// index of last v's neighbour from C array
		index = neighboursPrefixSum[threadIdx.x];
		visited[v] = newColor;
	}
	if (v == 13)
	{
		//neighbours[0] = 1;
	}
	int blockProgress = 0;
	int remain;
	while ((remain = *totalNeighbours - blockProgress) > 0)
	{
		if (v != -1 && index < *totalNeighbours && index >= 0)
		{
			// put vertex v's neighbours to shared memory
			while ((index < blockProgress + THREAD_NUM)
				&& (r < rEnd))
			{
				neighbours[index - blockProgress] = r; // r shows where current v's neighbour is in C array
				index++;
				r++;
			}
		}
		__syncthreads();
		// each thread gets a vertex from shared memory
		if (threadIdx.x < remain && threadIdx.x < THREAD_NUM) {
			int v = C[neighbours[threadIdx.x]];
			if (visited[v] != startingColor)
			{
				v = -1;
				neighbourCountsOut[blockProgress + threadIdx.x] = 0;
			}
			else
			{
				int newR = R[v];
				int newREnd = R[v + 1];
				neighbourCountsOut[blockProgress + threadIdx.x] = newREnd - newR;
			}
			queueOut[blockProgress + threadIdx.x] = v;
		}
		blockProgress += THREAD_NUM;
		__syncthreads();
	}
}