float2 TextureCoordToPerspectiveCorrected(
	float2 textureCoord,
	float2 textureSize)
{	
	float2 result = textureCoord;

	result *= 2;
	result -= 1;
	
	if (textureSize.x > textureSize.y)
	{
		result.x *= (textureSize.x / textureSize.y);
	}
	else
	{
		result.y *= (textureSize.y / textureSize.x);
	}

	return result;
}

float2 TransformFromCanvasTextureToFramedTexture(
	float2 canvasTextureCoord,
	float2 canvasTextureSize,
	float2 framedTextureSize)
{	
	float2 result = canvasTextureCoord;

	float canvasAspectRatio = (canvasTextureSize.x / canvasTextureSize.y);
	float framedAspectRatio = (framedTextureSize.x / framedTextureSize.y);

	if (framedAspectRatio < canvasAspectRatio)
	{
		float relativeAspectRatio = (canvasAspectRatio / framedAspectRatio);

		result.x *= relativeAspectRatio;
		result.x -= (0.5 * (relativeAspectRatio - 1.0));
	}
	else
	{
		float relativeAspectRatio = (framedAspectRatio / canvasAspectRatio);

		result.y *= relativeAspectRatio;
		result.y -= (0.5 * (relativeAspectRatio - 1.0));
	}

	return result;
}

bool TextureCoordIsInBounds(
	float2 texCoord)
{
	return (
		step(0.0, texCoord.x) * step(texCoord.x, 1.0) *
		step(0.0, texCoord.y) * step(texCoord.y, 1.0));
}