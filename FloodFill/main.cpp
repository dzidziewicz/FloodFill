#include <iostream>
#include "floodFillWithCpu.h"
#include "hostFunctions.h"

using namespace std;

int main()
{
	int height = 1;
	int width = 5;

	int** array = new int*[height];
	for (int i = 0; i < height; i++)
	{
		array[i] = new int[width];
		for (int j = 0; j < width; j++)
			array[i][j] = 0;
	}
	array[0][3] = 4;
	//floodFillWithCpu(array, height, width, 3, 2, 1);

	bfs(array, height, width, 0, 0, 1);

	for (int i = 0; i < height; i++)
	{
		for (int j = 0; j < width; j++)
			cout << array[i][j] << " ";
		cout << endl;
	}
}

