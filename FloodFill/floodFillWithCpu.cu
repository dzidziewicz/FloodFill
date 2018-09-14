
#include "floodFillWithCpu.h"
#include <stdlib.h>
#include <iostream>
#include <queue>

using namespace std;

void floodFillWithCpu(int** array, int rows, int cols, int xStarting, int yStarting, int newColor)
{
	int vertexCount = rows * cols;
	bool* visited = new bool[vertexCount];
	for (int i = 0; i < vertexCount; i++)
		visited[i] = false;
	queue<int> queue;
	int oldColor = array[yStarting][xStarting];

	int startingPoint = xStarting + yStarting * cols;
	queue.push(startingPoint);

	while (!queue.empty())
	{
		int v = queue.front();
		queue.pop();

		int y = v / cols;
		int x = v % cols;
		array[v / cols][v % cols] = newColor;

		if (y > 0 && !visited[v - cols] && array[y - 1][x] == oldColor)
		{
			queue.push(v - cols);
			visited[v - cols] = true;
		}
		if (y < rows - 1 && !visited[v + cols] && array[y + 1][x] == oldColor)
		{
			queue.push(v + cols);
			visited[v + cols] = true;
		}
		if (x > 0 && !visited[v - 1] && array[y][x - 1] == oldColor)
		{
			queue.push(v - 1);
			visited[v - 1] = true;
		}
		if (x < cols - 1 && !visited[v + 1] && array[y][x + 1] == oldColor)
		{
			queue.push(v + 1);
			visited[v + 1] = true;
		}
	}

	/*int size = n * m;
	struct Node* columnIndices = (struct Node*) malloc(size * sizeof(struct Node));
	for (int i = 0; i < size; i++)
	{
	struct Node node;
	node.r =
	}*/
}

void transform1Dto2D(int* x, int* y, int index1D, int)
{

}

