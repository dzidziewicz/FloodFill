
#include "floodFillWithCpu.h"
#include <stdlib.h>
#include <iostream>
#include <queue>

using namespace std;

int* floodFillWithCpu(int* arr, int rows, int cols, int xStarting, int yStarting, int newColor)
{
	int vertexCount = rows * cols;
	int* arrayToFill = (int*)malloc(vertexCount * sizeof(int));
	for (int i = 0; i < vertexCount; i++)
	{
		arrayToFill[i] = arr[i];
	}

	bool* visited = (bool*)malloc(vertexCount * sizeof(bool));
	for (int i = 0; i < vertexCount; i++)
		visited[i] = false;
	queue<int> queue;
	int startingPoint = xStarting + yStarting * cols;

	int oldColor = arr[startingPoint];

	queue.push(startingPoint);

	while (!queue.empty())
	{
		int v = queue.front();
		queue.pop();

		if (arr[v] != oldColor || visited[v]) continue;
		visited[v] = true;
		arrayToFill[v] = newColor;

		int x = v % cols;
		int y = v / cols;

		if (x == 0 && y == 0)
		{
			queue.push(v + 1);
			queue.push(v + cols);
		}
		else if (x == 0 && y == rows - 1)
		{
			queue.push(v + 1);
			queue.push(v - cols);
		}
		else if (x == cols - 1 && y == 0)
		{
			queue.push(v - 1);
			queue.push(v + cols);
		}
		else if (x == cols - 1 && y == rows - 1)
		{
			queue.push(v - 1);
			queue.push(v - cols);
		}
		else if (x == 0)
		{
			queue.push(v + 1);
			queue.push(v + cols);
			queue.push(v - cols);
		}
		else if (x == cols - 1)
		{
			queue.push(v - 1);
			queue.push(v + cols);
			queue.push(v - cols);
		}
		else if (y == 0)
		{
			queue.push(v - 1);
			queue.push(v + 1);
			queue.push(v + cols);
		}
		else if (y == rows - 1)
		{
			queue.push(v - 1);
			queue.push(v + 1);
			queue.push(v - cols);
		}
		else
		{
			queue.push(v - 1);
			queue.push(v + 1);
			queue.push(v + cols);
			queue.push(v - cols);
		}

	}
	return arrayToFill;
}

void transform1Dto2D(int* x, int* y, int index1D, int)
{

}

