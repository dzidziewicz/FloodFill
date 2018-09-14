#pragma once
#include "cuda_runtime.h"

void bfs(int** array, int height, int width, int xStarting, int yStarting, int newColor);

int getEdgesCount(int rows, int cols);

void prepareArrays(int* inputArr, int** R, int** C, int rows, int cols);

cudaError_t deviceMalloc(int** dest, int length);

cudaError_t deviceMemcpy(int* dest, int* source, int length, cudaMemcpyKind direction);
