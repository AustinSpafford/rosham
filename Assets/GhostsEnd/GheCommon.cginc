// Format: [x-offset, y-offset, index-of-complimentary-cell]
static const float3 kNeighborhoodKernel[8] =
{
	float3(-1, 1, 7),  float3(0, 1, 6),  float3(1, 1, 5),
	float3(-1, 0, 4),                    float3(1, 0, 3),
	float3(-1, -1, 2), float3(0, -1, 1), float3(1, -1, 0),
};

int FloatToIntRound(
	float value)
{
	return int(value + 0.5);
}

bool DirectionsAreEqual(
	float first, 
	float second)
{
	return (((first - 0.01) < second) && (second < (first + 0.01)));
}

float ReverseDirection(
	float direction)
{
	return
		(direction < -0.1) ?
			-1.0 : // Invalid directions reverse into still being invalid.
			kNeighborhoodKernel[FloatToIntRound(direction)].z;
}