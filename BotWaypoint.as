
CWaypoints g_Waypoints;

const int W_FL_JUMP = 1;
const int W_FL_CROUCH = 2;
const int W_FL_END_LEVEL = 4;

const int MAX_WAYPOINTS = 1024;

// apparently "Waypoint" is a reserved class name
class CWaypoint
{
	// link to waypoint id
	array<uint> m_PathsFrom;
	array<uint> m_PathsTo;

	int iIndex;

	Vector m_vOrigin;
	// flags such as Jump, crouch etc
	uint m_iFlags;
	// true if in use, false if can overwrite
	bool m_bUsed;
	
	CWaypoint ()
	{
		m_bUsed = false;
		m_iFlags = 0;
	}
	
	float distanceFrom ( Vector vecLocation )
	{
		return (m_vOrigin - vecLocation).Length();
	}

	int numPaths ( )
	{
		return m_PathsTo.length();
	}

	int getPath ( int i )
	{
		return m_PathsTo[i];
	}

	void addWaypointType ( int type )
	{
		 m_iFlags |= type;
	}

	void removeWaypointType ( int type )
	{
		m_iFlags &= ~type;
	}

	string getSerialized ()
	{
		return formatFloat(m_vOrigin.x) + "," + formatFloat(m_vOrigin.y) + "," + formatFloat(m_vOrigin.z) + "," + formatFloat(m_vOrigin.x) + "," + formatUInt(m_iFlags);
	}

	void Delete ()
	{
		m_bUsed = false;
	}

	void Place ( int index, Vector loc )
	{
		m_vOrigin = loc;
		m_bUsed = true;
		iIndex = index;
	}

	void Clear ()
	{
		m_PathsFrom = {};
		m_PathsTo = {};
		m_bUsed = false;
		m_iFlags = 0;
	}

}


CWaypoint@ ReadWaypoint ( string line )
{
	array<string> csv = line.split(",");

	Vector vecLoc;
	int iFlags;

	vecLoc.x = parseFloat(csv[0]);
	vecLoc.y = parseFloat(csv[1]);
	vecLoc.z = parseFloat(csv[2]);
	iFlags = parseUint(csv[3]);

	return CWaypoint(vecLoc,iFlags);
}	

class CWaypoints
{
	// Max waypoint is 1024 
	private array<CWaypoint> m_Waypoints(MAX_WAYPOINTS);

	int m_iNumWaypoints = 0;

	CWaypoint@ getWaypointAtIndex ( uint idx )
	{
		return m_Waypoints[idx];
	}

	int getWaypointIndex ( CWaypoint@ pWpt )
	{
		return pWpt.iIndex;
	}
	
	void addWaypoint ( Vector vecLocation, int flags )
	{
		int index = freeWaypointIndex();

		if ( index != -1 )
		{	
			m_Waypoints[index].Place(index,vecLocation);
		
			if ( index == m_iNumWaypoints )
				m_iNumWaypoints++;	
		}
	}

	int freeWaypointIndex ()
	{
		for( int i = 0; i < m_iNumWaypoints; i ++ )
		{
			if ( m_Waypoints[i].m_bUsed == false )
				return i;
		}

		return -1;
	}
	
	int getNearestWaypointIndex ( Vector vecLocation )
	{
		int nearestWptIdx = -1;
		float distance = 0;
		float minDistance = 0;
		
		for( int i = 0; i < m_iNumWaypoints; i ++ )
		{
			distance = m_Waypoints[i].distanceFrom(vecLocation);
			
			if ( (nearestWptIdx == -1 ) || (minDistance < distance) )
			{
				minDistance = distance;
				nearestWptIdx = i;
			}
		}
		
		return nearestWptIdx;
	}

	void deleteWaypoint ( uint idx )
	{		
		for ( int i = 0; i < m_iNumWaypoints; i ++ )
		{
			CWaypoint@ pWpt = m_Waypoints[i];

			for ( uint j = 0; j < pWpt.m_PathsFrom.length(); j ++ )
			{
				if ( pWpt.m_PathsFrom[j] == idx )
				{
					pWpt.m_PathsFrom.removeAt(j);
					break;
				}
			}

			for ( uint j = 0; j < pWpt.m_PathsTo.length(); j ++ )
			{
				if ( pWpt.m_PathsTo[j] == idx )
				{
					pWpt.m_PathsTo.removeAt(j);
					break;
				}
			}
		}

		CWaypoint@ pDelete = g_Waypoints.getWaypointAtIndex(idx);

		pDelete.Delete();
	}

	void ClearWaypoints ()
	{
		for( uint i = 0; i < MAX_WAYPOINTS; i ++ )
		{
			m_Waypoints[i].Clear();
		}
	}

	bool Load ()
	{
		file f;
		// Open the file in 'read' mode
		if( f.open(g_Engine.mapname + ".wpt", "r") >= 0 ) 
		{
			// Read the whole file into the string buffer
			string str;

			ClearWaypoints();
			
			while ( (str = f.readLine()) !is null )
			{
				m_Waypoints.insertLast(ReadWaypoint(str));				
			}

			f.close();
		}
	}

	bool Save ()
	{
		file f;
		// Open the file in 'read' mode
		if( f.open(g_Engine.mapname + ".wpt", "w") >= 0 ) 
		{
			for ( uint i = 0; i < m_iNumWaypoints; i ++ )
			{
				CWaypoint@ wpt = m_Waypoints[i];
			
				f.WriteString(wpt.getSerialized());
			}

			f.close();
		}
	}
}
	const int NavigatorState_Complete = 0;
	const int NavigatorState_InProgress = 1;
	const int NavigatorState_Fail = 2;
// ------------------------------------
// NAVIGATOR - 	START (WIP)
// ------------------------------------
final class RCBotNavigator 
{

	
	

	int state;

	int iStart;
	int iGoal;

	int iMaxLoops = 200;
	int iLastNode;
	array<AStarNode> paths(MAX_WAYPOINTS);
	AStarNode@ curr;

	CWaypoint@ pStartWpt;
	CWaypoint@ pGoalWpt;

	array<AStarNode@> m_theOpenList;

	void open ( AStarNode@ pNode )
	{
		if ( pNode.isOpen() == false )
		{
			pNode.open();
			//m_theOpenList.push_back(pNode);
			m_theOpenList.insertLast(pNode);
		}
	}

	RCBotNavigator ( Vector vFrom , Vector vTo )
	{
		iStart = g_Waypoints.getNearestWaypointIndex(vFrom);
		iGoal = g_Waypoints.getNearestWaypointIndex(vTo);

		if ( iStart == -1 || iGoal == -1 )
		{
			state = NavigatorState_Fail;
		}
		else
		{
			state = NavigatorState_InProgress;
			curr = @paths[iStart];
			curr.setWaypoint(iStart);
			pStartWpt = g_Waypoints.getWaypointAtIndex(iStart);
			pGoalWpt = g_Waypoints.getWaypointAtIndex(iGoal);
			curr.setHeuristic(0);
			open(curr);
			iLastNode = iStart;
		}
	}

	int run ()
	{		
		int iLoops = 0;
		int iPath;

		while ( state == NavigatorState_InProgress )
		{
			iLoops++;

			if ( iLoops > iMaxLoops )
				break;

			if ( m_theOpenList.length() == 0 )
			{
				state = NavigatorState_Fail;
				break;
			}

			if ( curr.getWaypoint() == iGoal )
			{
				state = NavigatorState_Complete;
				break;
			}

			CWaypoint@ currWpt = g_Waypoints.getWaypointAtIndex(curr.getWaypoint());
			CWaypoint@ succWpt;
			AStarNode@ succ;
			int iCurrentNode = curr.getWaypoint();
			int iMaxPaths = currWpt.numPaths();

			for ( iPath = 0; iPath < iMaxPaths; iPath ++ )
			{
				int iSucc = currWpt.getPath(iPath);
				

				if ( iSucc == iLastNode )
					continue;
				if ( iSucc == iCurrentNode ) // argh?
					continue;	

				/*(if ( m_lastFailedPath.bValid )
				{
					if ( m_lastFailedPath.iFrom == iCurrentNode ) 
					{
						// failed this path last time
						if ( m_lastFailedPath.iTo == iSucc )
						{
							m_lastFailedPath.bSkipped = true;
							continue;
						}
					}
				}*/

				@succ = @paths[iSucc];
				succWpt = g_Waypoints.getWaypointAtIndex(iSucc);

				//if ( (iSucc != m_iGoalWaypoint) && !m_pBot.canGotoWaypoint(vOrigin,succWpt,currWpt) )
			//		continue;

				float fCost = curr.getCost()+(succWpt.distanceFrom(currWpt.m_vOrigin));

				if ( succ.isOpen() || succ.isClosed() )
				{
					if ( succ.getParent() != -1 )
					{
						if ( fCost >= succ.getCost() )
							continue; // ignore route
					}
					else
						continue;
				}

				succ.unClose();

				succ.setParent(iCurrentNode);

				succ.setCost(fCost);	

				succ.setWaypoint(iSucc);

				if ( succ.heuristicSet() == false )		
				{
					float h = pStartWpt.distanceFrom(succWpt.m_vOrigin) + pGoalWpt.distanceFrom(succWpt.m_vOrigin);

					succ.setHeuristic(h);
				}

				// Fix: do this AFTER setting heuristic and cost!!!!
				if ( succ.isOpen() == false )
				{
					open(succ);
				}

			}

			curr.close(); // close chosen node

			iLastNode = iCurrentNode;				
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

class AStarNode
{
	AStarNode() { m_fCost = 0; m_fHeuristic = 0; m_iFlags = 0; m_iParent = -1; m_iWaypoint = -1; }
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
	float getHeuristic () { return m_fHeuristic; } 

	////////////////////////////////////////////////////////
	void setFlag ( int iFlag ) { m_iFlags |= iFlag; }
	bool hasFlag ( int iFlag ) { return ((m_iFlags & iFlag) == iFlag); }
	void removeFlag ( int iFlag ) { m_iFlags &= ~iFlag; }
	/////////////////////////////////////////////////////////
	int getParent () { if ( hasFlag(FL_ASTAR_PARENT) ) return m_iParent; else return -1; }
	void setParent ( int iParent ) 
	{ 
		m_iParent = iParent; 

		if ( m_iParent == -1 )
			removeFlag(FL_ASTAR_PARENT); // no parent
		else
			setFlag(FL_ASTAR_PARENT);
	}
	////////////////////////////////////////////////////////
	float getCost () { return m_fCost; }
	void setCost ( float fCost ) { m_fCost = fCost; }
	////////////////////////////////////////////////////////
	// for comparison
	bool precedes ( AStarNode@ other ) const
	{
		return (m_fCost+m_fHeuristic) < (other.getCost() + other.getHeuristic());
	}
	void setWaypoint ( int iWpt ) { m_iWaypoint = iWpt; }
	int getWaypoint () { return m_iWaypoint; }

	private float m_fCost;
	private float m_fHeuristic;
	private int  m_iFlags;
	private int m_iParent;
	private int m_iWaypoint;
};

// Insertion sorted list
final class AStarListNode
{
	AStarListNode ( AStarNode@ data )
	{
		@m_Data = data;
		@m_Next = null;
	}
	AStarNode@ m_Data;
	AStarListNode@ m_Next;
};

final class AStarOpenList
{
	AStarOpenList()
	{
		@m_Head = null;
	}

	bool empty ()
	{
		return (m_Head is null);
	}

	AStarNode@ top ()
	{
		if ( m_Head is null )
			return null;
		
		return m_Head.m_Data;
	}

	void pop ()
	{
		if ( m_Head !is null )
		{
			AStarListNode@ t = m_Head;

			@m_Head = m_Head.m_Next;
		}
	}

	void add ( AStarNode@ data )
	{
		AStarListNode@ newNode = AStarListNode(data);
		AStarListNode@ t;
		AStarListNode@ p;

		if ( m_Head is null )
			m_Head = newNode;
		else
		{
			if ( data.precedes(m_Head.m_Data) )
			{
				@newNode.m_Next = m_Head;
				@m_Head = newNode;
			}
			else
			{
				@p = m_Head;
				@t = m_Head.m_Next;

				while ( t !is null )
				{
					if ( data.precedes(t.m_Data) )
					{
						@p.m_Next = newNode;
						@newNode.m_Next = t;
						break;
					}

					@p = t;
					@t = t.m_Next;
				}

				if ( t is null )
					@p.m_Next = newNode;

			}
		}
	}

	void destroy ()
	{
		AStarListNode@ t;

		while ( m_Head !is null )
		{
			@t = m_Head;
			@m_Head = m_Head.m_Next;
			//delete t;
			@t = null;
		}

		@m_Head = null;
	}
	
	private AStarListNode@ m_Head;
};