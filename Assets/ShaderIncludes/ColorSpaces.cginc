float3 HsbToRgb(
	float3 hsbColor)
{
	// From: Iñigo Quiles 
	// https://www.shadertoy.com/view/MsS3Wc
	float3 rgb = clamp(abs(fmod((hsbColor.x * 6) + float3(0, 4, 2), 6) - 3) - 1, 0, 1);
	rgb = (rgb * rgb * (3 - (2 * rgb)));
	return (hsbColor.z * lerp(float3(1, 1, 1), rgb, hsbColor.y));
}

float3 HsbToRgb(
	float hueFraction,
	float saturationFraction,
	float brightnessFraction)
{
	return HsbToRgb(float3(hueFraction, saturationFraction, brightnessFraction));
}
