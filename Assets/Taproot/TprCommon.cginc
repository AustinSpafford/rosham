#define kTypeBase                 0.0
#define kTypeBlueprint            1.0
#define kTypeConveyorConnected    2.0
#define kTypeConveyorDisconnected 3.0
#define kTypeGround               4.0
#define kTypeObstacle             5.0
#define kTypeVein                 6.0

bool IsZero(
	float value)
{
	return ((-0.001 < value) && (value < 0.001));
}

bool IsType(
	float candidate, 
	float type)
{
	return IsZero(candidate - type);
}

float4 ConvertToBlueprint(
	float4 self)
{
	float4 result = self;

#if 0
	result.x = kTypeBlueprint;
	result.y = -1.0;
	result.w = -1.0; // Consume 1 plate to build the conveyor.
#else
	result.x = kTypeConveyorDisconnected;
	result.y = -1.0;
#endif

	return result;
}
