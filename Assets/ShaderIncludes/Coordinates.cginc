float2 TextureCoordToPerspectiveCorrected(
	float2 textureCoord,
	float2 textureSize)
{	
	float2 result = textureCoord;

	result *= 2;
	result -= 1;

	result.x *= (textureSize.x / textureSize.y);

	return result;
}