
RCBotWaypoints g_Waypoints;

// apparently "Waypoint" is a reserved class name
class RCBotWaypoint
{
	array<RCBotWaypoint@> m_Paths;
	
	protected Vector m_vecLocation;
	
	int Flags;
	
	RCBotWaypoint ( Vector vecLocation )
	{
		m_vecLocation = vecLocation;		
	}
	
	float distanceFrom ( Vector vecLocation )
	{
		return (m_vecLocation - vecLocation).Length();
	}

	int numPaths ( )
	{
		return m_Paths.length();
	}

	RCBotWaypoint@ getPath ( int i )
	{
		return m_Paths[i];
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

// ------------------------------------
// NAVIGATOR - 	START (WIP)
// ------------------------------------
final class RCBotNavigator 
{
	enum NavigatorState
	{
		NavigatorState_InProgress,
		NavigatorState_Fail,
		NavigatorState_Complete
	}

	private NavigatorState state = NavigatorState_Init;
	
	array<Waypoint@> m_pNavList;
	array<AStarNode@> m_pOpenList;
	array<AStarNode@> m_pNodes;

	AStarNode@ m_pCurrent;
	AStarNode@ m_pPrevious = null;

	int m_iMaxLoops = 200;
	int iLoops = 0;

	RCBotNavigator ( Vector vFrom, Vector vTo )
	{
		Waypoint@ pFrom = g_Waypoints.getNearestWaypoint(vFrom);
		Waypoint@ pTo = g_Waypoints.getNearestWaypoint(vTo);

		m_pWpt = pFrom;

		// no waypoint at To or From point
		if ( pFrom is null || pTo is null )
			state = NavigatorState_Fail;
		else
		{
			AStarNode@ newNode = AStarNode(pFrom);
			m_pCurrent = newNode;
			m_pOpenList.insertLast(newNode);
		}
		
	}

	/*
	 * FindPath
	 * @param vFrom 
	 * @param vTo
	 */
	NavigatorState Run ()
	{
		while ( state == NavigatorState_InProgress && m_pOpenList.length() > 0 && iLoops < m_iMAxLoops )
		{
			iLoops ++;

			RCBotWaypoint@ pWpt = m_pCurrent.m_pWaypoint;
		
			int iPaths = m_pWpt.numPaths();

			for ( uint iPath = 0; iPath < iPaths; iPath ++ )
			{
				AStarNode@ pSucc = m_pNodes.find();

				
			}
		}

		return state;
	}
}
// ------------------------------------
// NAVIGATOR - 	END
// ------------------------------------
const int FL_ASTAR_CLOSED 	= 1;
const int FL_ASTAR_PARENT 	= 2;
const int FL_ASTAR_OPEN	 	= 4;
const int FL_HEURISTIC_SET 	= 8;

final class AStarNode
{
	AStarNode() { m_fCost = 0.0; m_fHeuristic = 0.0f; m_iFlags = 0; m_pParent = null; m_pWaypoint = null; }
	///////////////////////////////////////////////////////
	void close () { setFlag(FL_ASTAR_CLOSED); }
	void unClose () { removeFlag(FL_ASTAR_CLOSED); }
	bool isOpen () { return hasFlag(FL_ASTAR_OPEN); }
	void unOpen () { removeFlag(FL_ASTAR_OPEN); }
	bool isClosed () { return hasFlag(FL_ASTAR_CLOSED); }
	void open () { setFlag(FL_ASTAR_OPEN); }
	//////////////////////////////////////////////////////	
	void setHeuristic ( float fHeuristic ) { m_fHeuristic = fHeuristic; setFlag(FL_HEURISTIC_SET); }
	bool heuristicSet () { return hasFlag(FL_HEURISTIC_SET); }
	const float getHeuristic () { return m_fHeuristic; } const
	
	////////////////////////////////////////////////////////
	void setFlag ( int iFlag ) { m_iFlags |= iFlag; }
	bool hasFlag ( int iFlag ) { return ((m_iFlags & iFlag) == iFlag); }
	void removeFlag ( int iFlag ) { m_iFlags &= ~iFlag; }
	/////////////////////////////////////////////////////////
	int getParent () { if ( hasFlag(FL_ASTAR_PARENT) ) return m_iParent; else return -1; }
	void setParent ( RCBotWaypoint@ pWpt ) 
	{ 
		@m_pParent = pWpt; 

		if ( @m_pParent is null )
			removeFlag(FL_ASTAR_PARENT); // no parent
		else
			setFlag(FL_ASTAR_PARENT);
	}
	////////////////////////////////////////////////////////
	const float getCost () { return m_fCost; } const
	void setCost ( float fCost ) { m_fCost = fCost; }
	////////////////////////////////////////////////////////
	// for comparison
	bool precedes ( AStarNode@ other ) const
	{
		return (m_fCost+m_fHeuristic) < (other->getCost() + other->getHeuristic());
	}
	void setWaypoint ( RCBotWaypoint@ pWpt ) { @m_pWaypoint = pWpt; }
	int getWaypoint () { return m_iWaypoint; }
private:
	float m_fCost;
	float m_fHeuristic;
	int m_iFlags;
	RCBotWaypoint@ m_pParent;
	RCBotWaypoint@ m_pWaypoint;
}

