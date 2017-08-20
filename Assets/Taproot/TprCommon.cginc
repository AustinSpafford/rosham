#define kTypeBase                 0.0
#define kTypeBlueprint            1.0
#define kTypeConveyorConnected    2.0
#define kTypeConveyorDisconnected 3.0
#define kTypeGround               4.0
#define kTypeObstacle             5.0
#define kTypeVein                 6.0

bool IsType(
	float candidate, 
	float type)
{
	return (((type - 0.001) < candidate) && (candidate < (type + 0.001)));
}
