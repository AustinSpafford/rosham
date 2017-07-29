#define kTypeBase      0.0
#define kTypeBlueprint 1.0
#define kTypeConveyor  2.0
#define kTypeGround    3.0
#define kTypeObstacle  4.0
#define kTypeVein      5.0

bool IsType(
	float candidate, 
	float type)
{
	return (((type - 0.001) < candidate) && (candidate < (type + 0.001)));
}
