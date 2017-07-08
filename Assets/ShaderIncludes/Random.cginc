float Random(
	float2 input)
{
	// From: https://thebookofshaders.com/10/
	return frac(
		sin(dot(input.xy, float2(12.9898, 78.233))) * 
		43758.5453123);
}
