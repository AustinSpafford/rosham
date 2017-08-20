// Format: [x-offset, y-offset], listed in counter-clockwise order.
static const float2 kNeighborhoodKernel[8] =
{
	float2(1, 0),
	float2(1, 1),
	float2(0, 1),
	float2(-1, 1),
	float2(-1, 0),    
	float2(-1, -1),
	float2(0, -1),
	float2(1, -1),
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

float SnapDirection(
	float unboundedDirection)
{
	return floor(fmod((unboundedDirection + 8.5), 8.0));
}

float ReverseDirection(
	float direction)
{
	return SnapDirection(direction + 4.0);
}