#pragma once

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "deviceFunctions.h"

__global__ void gatherScan(int* queueIn, int*queueOut, int* C, int* R,
	int* neighboursPrefixSum, int* visited, int* totalNeighbours,
	int* neighbourCountsOut, int newColor, int startingColor)
{
	__shared__ int neighbours[THREAD_NUM];

	int v = queueIn[threadIdx.x];
	int r, rEnd, index;
	if (v != -1)
	{
		r = R[v];					// index of first v's neighbour from C array
		rEnd = R[v + 1];			// index of last v's neighbour from C array
		index = neighboursPrefixSum[threadIdx.x];	// index at which this thread will start putting v's neighbours in queueOut
		visited[v] = newColor;		
	}

	int blockProgress = 0;	// number of vertices put in queueOut in all previous iteration of main while loop
	int remain;
	while ((remain = *totalNeighbours - blockProgress) > 0)
	{
		if (v != -1 && index < *totalNeighbours && index >= 0)	// if index is out of range <0, totalNeighbours>, this thread should be idle
		{
			// put vertex v's neighbours to shared memory
			while ((index < blockProgress + THREAD_NUM)
				&& (r < rEnd))
			{
				neighbours[index - blockProgress] = r; // r shows where currently viewed v's neighbour is in C array
				index++;
				r++;
			}
		}
		__syncthreads();
		// each thread gets a vertex from shared memory
		if (threadIdx.x < remain && threadIdx.x < THREAD_NUM) {
			int n = C[neighbours[threadIdx.x]]; // v's neighbour
			if (visited[n] != startingColor)
			{
				n = -1;				// we don't want to process n in next bfs iteration
				neighbourCountsOut[blockProgress + threadIdx.x] = 0;
			}
			else
			{
				int newR = R[n];
				int newREnd = R[n + 1];
				neighbourCountsOut[blockProgress + threadIdx.x] = newREnd - newR; // save number of n's neighbours
			}
			queueOut[blockProgress + threadIdx.x] = n;
		}
		blockProgress += THREAD_NUM;
		__syncthreads();
	}
}