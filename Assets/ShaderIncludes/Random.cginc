float Random(
	float2 testCoord)
{
	// From: https://thebookofshaders.com/10/
	return frac(
		sin(dot(testCoord.xy, float2(12.9898, 78.233))) * 
		43758.5453123);
}

float2 Random2(
	float2 testCoord)
{
	// From: https://www.shadertoy.com/view/Xd23Dh
	// (just removed the last dimension)
	float2 testPointInGeneratorSpace = float2(
		dot(testCoord, float2(127.1, 311.7)),
		dot(testCoord, float2(269.5, 183.3)));

	return frac(sin(testPointInGeneratorSpace) * 43758.5453);
}

float3 Random3(
	float2 testCoord)
{
	// From: https://www.shadertoy.com/view/Xd23Dh
	float3 testPointInGeneratorSpace = float3(
		dot(testCoord, float2(127.1, 311.7)),
		dot(testCoord, float2(269.5, 183.3)),
		dot(testCoord, float2(419.2, 371.9)));

	return frac(sin(testPointInGeneratorSpace) * 43758.5453);
}

float4 Random4(
	float2 testCoord)
{
	// From: https://www.shadertoy.com/view/Xd23Dh
	float4 testPointInGeneratorSpace = float4(
		dot(testCoord, float2(127.1, 311.7)),
		dot(testCoord, float2(269.5, 183.3)),
		dot(testCoord, float2(419.2, 371.9)),
		dot(testCoord, float2(810.5, 235.0)));

	return frac(sin(testPointInGeneratorSpace) * 43758.5453);
}

float VoroNoise(
	float2 testCoord,
	float jitterFraction,
	float smoothingFraction)
{
	// From: http://www.iquilezles.org/www/articles/voronoise/voronoise.htm

	float2 testWhole = floor(testCoord);
	float2 testFraction = frac(testCoord);

	float thresholdingPower = lerp(1.0, 64.0, pow((1.0 - smoothingFraction), 4.0));

	float accumulator = 0.0;
	float totalWeight = 0.0;

	for (int xIndex = -2; xIndex <= 2; xIndex++)
	{
		for (int yIndex = -2; yIndex <= 2; yIndex++)
		{
			float2 cellRelative = float2(float(xIndex), float(yIndex));
			float2 cellCoord = (testWhole + cellRelative);

			float2 cellJitter = (Random2(cellCoord) * jitterFraction);
			float cellValue = Random(cellCoord);

			float2 selfToCell = ((cellRelative + cellJitter) - testFraction);
			float cellWeight = pow(
				smoothstep(1.414, 0.0, length(selfToCell)),
				thresholdingPower);

			accumulator += (cellWeight * cellValue);
			totalWeight += cellWeight;
		}
	}

	return (accumulator / totalWeight);
}
