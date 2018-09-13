#pragma once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <device_functions.h>

#define THREAD_NUM 10

__global__ void gatherScan(int* queueIn, int*queueOut, int* C, int* R,
	//int* rArrIn, int* rEndArrayIn,
	int* neighboursPrefixSum,
	int* visited, int* totalNeighbours,
	//int* rArrOut, int* rEndArrOut, 
	int* neighbourCountsOut);