#pragma once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <device_functions.h>

#define THREAD_NUM 100

__global__ void gatherScan(int* queueIn, int*queueOut, int* C, int* R,
	int* neighboursPrefixSum,
	int* visited, int* totalNeighbours,
	int* neighbourCountsOut, int newColor, int startingColor);