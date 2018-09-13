#pragma once

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "deviceFunctions.h"

__global__ void gatherScan(int* queueIn, int*queueOut, int* C, int* R, 
	//int* rArrIn, int* rEndArrayIn,
	int* neighboursPrefixSum,
	int* visited, int* totalNeighbours, 
	//int* rArrOut, int* rEndArrOut, 
	int* neighbourCountsOut)
{
	__shared__ int neighbours[THREAD_NUM];

	if (threadIdx.x > 0)
	{
		neighbours[0] = 1;
	}

	int v = queueIn[threadIdx.x];
	int r, rEnd, index;
	if (v != -1)
	{
		r = R[v];// rArrIn[v];					// index of first v's neighbour from C array
		rEnd = R[v + 1];// rEndArrayIn[v];			// index of last v's neighbour from C array
		index = neighboursPrefixSum[threadIdx.x];
		visited[v] = 1;
	}
	int blockProgress = 0;
	int remain;
	while ((remain = *totalNeighbours - blockProgress) > 0)
	{
		if (v != -1)
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
			queueOut[blockProgress + threadIdx.x] = v;
			int newR = /*rArrOut[blockProgress + threadIdx.x] =*/ R[v];
			int newREnd/* = rEndArrOut[blockProgress + threadIdx.x] */ = R[v + 1];
			neighbourCountsOut[blockProgress + threadIdx.x] = newREnd - newR;
		}
		blockProgress += THREAD_NUM;
		__syncthreads();
	}
}