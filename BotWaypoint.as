// apparently "Waypoint" is a reserved class name
class RCBotWaypoint
{
	private array<RCBotWaypoint@> m_To;
	
	protected Vector m_vecLocation;
	
	private int Flags;
	
	RCBotWaypoint ( Vector vecLocation )
	{
		m_vecLocation = vecLocation;		
	}
	
	float distanceFrom ( Vector vecLocation )
	{
		return (m_vecLocation - vecLocation).Length();
	}

	void addWaypointType ( int type )
	{
		 Flags |= type;
	}

	void removeWaypointType ( int type )
	{
		Flags &= ~type;
	}
	
	int W_FL_JUMP = 1;
	int W_FL_CROUCH = 2;
	int W_FL_END_LEVEL = 4;
}

class RCBotWaypoints
{
	private array<RCBotWaypoint@> m_Waypoints;
	
	void addWaypoint ( Vector vecLocation )
	{
		m_Waypoints.insertLast( RCBotWaypoint ( vecLocation ) );
	}
	
	RCBotWaypoint@ getNearestWaypoint ( Vector vecLocation )
	{
		RCBotWaypoint@ nearestWpt = null;
		float distance = 0;
		float minDistance = 0;
		
		for( uint i = 0; i < m_Waypoints.length(); i ++ )
		{
			distance = m_Waypoints[i].distanceFrom(vecLocation);
			
			if ( (nearestWpt is null) || (minDistance < distance) )
			{
				minDistance = distance;
				@nearestWpt = m_Waypoints[i];
			}
		}
		
		return nearestWpt;
	}
}