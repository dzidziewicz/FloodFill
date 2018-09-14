#include "floodFillWithCpu.h"
#include "floodFillWithGpu.h"
#include "hostFunctions.h"
#include "deviceFunctions.h"

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <thrust/scan.h>

#include <stdlib.h>
#include <stdio.h>
using namespace std;
int* FloodFillWithGPU(int* arr, int rows, int cols, int xStarting, int yStarting, int newColor);

int main()
{
	int xStarting = 0, yStarting = 1;
	int newColor = 2;

	int arr1[9] = {		0, 0, 1,
						0, 0, 0,
						0, 0, 0 };

	int arr2[9] ={	0, 0, 1,
					0, 1, 1,
					0, 1, 0 };

	int arr3[36] = {	0, 0, 1, 0, 0, 0,
						0, 0, 0, 1, 0, 0,
						0, 0, 5, 5, 3, 0, 
						0, 0, 5, 5, 3, 0,
						0, 1, 5, 5, 0, 0,
						0, 1, 0, 0, 0, 0 };

	int arr4[36] = {	0, 0, 0, 0, 0, 0,
						0, 1, 1, 1, 1, 0,
						0, 1, 0, 0, 3, 0,
						0, 0, 3, 0, 3, 2,
						0, 0, 1, 1, 0, 0,
						0, 0, 0, 0, 0, 0,	};

	int arr5[42] = {	0, 1, 1, 1, 1, 0,
						0, 0, 1, 1, 1, 1,
						1, 0, 1, 1, 1, 1,
						1, 0, 1, 1, 1, 1,
						1, 0, 0, 0, 0, 1,
						1, 1, 1, 1, 0, 0, };

	int testRows[5] = { 3, 3, 6, 6, 7 };
	int testCols[5] = { 3, 3, 6, 6, 6 };
	int* testArrays[5] = { arr1, arr2, arr3, arr4, arr5 };

	for (int i = 0; i < 4; i++)
	{
		int rows = testRows[i], cols = testCols[i];
		int* arr = testArrays[i];

		printf("Starting point: (0, 1)\n");
		printf("New color: 2 \n");
		printf("\n");
		printf("Array before filling: \n");

		for (int i = 0, v = 0; i < rows; i++)
		{
			for (int j = 0; j < cols; j++)
				printf("%d ", arr[v++]);
			printf("\n");
		}
		printf("\n");

		int* colouredyGpu = FloodFillWithGPU(arr, rows, cols, xStarting, yStarting, newColor);

		printf("Array after filling by GPU: \n");

		for (int i = 0, v = 0; i < rows; i++)
		{
			for (int j = 0; j < cols; j++)
				printf("%d ", colouredyGpu[v++]);
			printf("\n");
		}
		printf("\n");

		int* colouredByCpu = floodFillWithCpu(arr, rows, cols, xStarting, yStarting, newColor);

		printf("Array after filling by CPU: \n");

		int equal = 1;
		for (int i = 0, v = 0; i < rows; i++)
		{
			for (int j = 0; j < cols; j++)
			{
				if (colouredByCpu[v] != colouredyGpu[v])
				{
					equal = 0;
				}
				printf("%d ", colouredByCpu[v++]);
			}
			printf("\n");
		}
			if(equal)
				printf("Arrays are equal! \n");
			else
				printf("Arrays are not equal! \n");


		printf("\n");
		printf("***********************************\n");
		printf("\n");
	}
}
