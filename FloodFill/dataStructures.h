#pragma once

struct Node
{
	int id;
	int r;			// index of this vertex's first neighbour in column-indices array
	int rEnd;		// index of the next vertex's first neighbour in column-indices array
	int value;
};

