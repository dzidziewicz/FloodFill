
#include "floodFillWithCpu.h"
#include <stdlib.h>
#include <iostream>
#include <queue>

using namespace std;

void floodFillWithCpu(int** array, int height, int width, int xStarting, int yStarting, int newColor)
{
	int vertexCount = height * width;
	bool* visited = new bool[vertexCount];
	for (int i = 0; i < vertexCount; i++)
		visited[i] = false;
	queue<int> queue;
	int oldColor = array[yStarting][xStarting];

	int startingPoint = xStarting + yStarting * width;
	queue.push(startingPoint);

	while (!queue.empty())
	{
		int v = queue.front();
		queue.pop();

		int y = v / width;
		int x = v % width;
		array[v / width][v % width] = newColor;

		if (y > 0 && !visited[v - width] && array[y - 1][x] == oldColor)
		{
			queue.push(v - width);
			visited[v - width] = true;
		}
		if (y < height - 1 && !visited[v + width] && array[y + 1][x] == oldColor)
		{
			queue.push(v + width);
			visited[v + width] = true;
		}
		if (x > 0 && !visited[v - 1] && array[y][x - 1] == oldColor)
		{
			queue.push(v - 1);
			visited[v - 1] = true;
		}
		if (x < width - 1 && !visited[v + 1] && array[y][x + 1] == oldColor)
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

