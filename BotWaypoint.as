
CWaypoints g_Waypoints;
CWaypointTypes g_WaypointTypes;

const int W_FL_JUMP = 1;
const int W_FL_CROUCH = 2;
const int W_FL_END_LEVEL = 4;
const int W_FL_AMMO = 8;
const int W_FL_HEALTH = 16;

const int MAX_WAYPOINTS = 1024;

void BotMessage ( string message )
{
	g_Game.AlertMessage( at_console, "[RCBOT]" + message );	
}

void drawBeam (CBasePlayer@ pPlayer, Vector start, Vector end, WptColor@ col )
{
	//BotMessage("Beam from " + formatFloat(start.x) + "," + formatFloat(start.y) + "," + formatFloat(start.z)+ "," + " to " + formatFloat(end.x)+ "," +formatFloat(end.y)+ "," + formatFloat(end.z) + "\n" );
		// PM - Use MSG_ONE_UNRELIABLE
		//    - no overflows!
	NetworkMessage message(MSG_ONE_UNRELIABLE, NetworkMessages::SVC_TEMPENTITY, pPlayer.edict());

	message.WriteByte(TE_BEAMPOINTS);
	message.WriteCoord(start.x);
	message.WriteCoord(start.y);
	message.WriteCoord(start.z);
	message.WriteCoord(end.x);
	message.WriteCoord(end.y);
	message.WriteCoord(end.z);
	message.WriteShort( g_EngineFuncs.ModelIndex("sprites/laserbeam.spr") );
	message.WriteByte( 1 ); // framestart
	message.WriteByte( 10 ); // framerate
	message.WriteByte( 10 ); // life in 0.1's
	message.WriteByte( 32 ); // width
	message.WriteByte( 2 );  // noise

	message.WriteByte( col.r );   // r, g, b
	message.WriteByte( col.g );   // r, g, b
	message.WriteByte( col.b );   // r, g, b

	message.WriteByte( col.a );   // brightness
	message.WriteByte( 1 );    // speed
	message.End();
}

class CWaypointType
{
	string m_szName;
	int m_iFlag;
	WptColor@ color;

	CWaypointType ( string name, int flag, WptColor@ col )
	{
		m_iFlag = flag;
		m_szName = name;
		@color = col;
	}

	bool isBitsInFlags ( int flags )
	{
		return (flags & m_iFlag) == m_iFlag;
	}

	void getColour (WptColor@ other)
	{

		other.r = color.r;
		other.g =  color.g;
		other.b =  color.b;
		other.a =  color.a;

	}

}


class WptColor
{
	WptColor ()
	{
		r=0;g=0;b=0;a=0;
	}

	WptColor ( int _r, int _g, int _b, int _a )
	{
		r=_r;
		g=_g;
		b=_b;
		a=_a;
	}

	WptColor ( int _r, int _g, int _b )
	{
		r=_r;
		g=_g;
		b=_b;
		a=200;
	}


	void mixColor ( WptColor@ other )
	{
		r = int( (0.5*r) + (0.5*other.r));
		g = int( (0.5*g) + (0.5*other.g));
		b = int( (0.5*b) + (0.5*other.b));
	}	
	int r;
	int g;
	int b;
	int a;
	
};

class CWaypointTypes
{
	array<CWaypointType@> m_Types;

	CWaypointTypes ()
	{
		m_Types.insertLast(CWaypointType("jump",W_FL_JUMP,WptColor(255,255,255)));
		m_Types.insertLast(CWaypointType("crouch",W_FL_CROUCH,WptColor(0,255,255)));
		m_Types.insertLast(CWaypointType("end",W_FL_END_LEVEL,WptColor(255,0,255)));
		m_Types.insertLast(CWaypointType("ammo",W_FL_AMMO,WptColor(50,255,50)));
		m_Types.insertLast(CWaypointType("health",W_FL_HEALTH,WptColor(255,50,50)));
	}

	WptColor getColour ( int flags )
	{
		WptColor colour = WptColor(0,0,255); // normal waypoint

		bool bNoColour = true;

		for ( uint i = 0; i < m_Types.length(); i ++ )
		{
			if ( m_Types[i].isBitsInFlags(flags) )
			{
				if ( bNoColour )
				{
					m_Types[i].getColour(colour);
					bNoColour = false;
				}
				else
				{
					WptColor col;
					m_Types[i].getColour(col);
					colour.mixColor(col);
				}
			}
		}

		return colour;
	}

	int findTypeFlag ( string type )
	{
		for ( uint i = 0; i < m_Types.length(); i ++ )
		{
			if ( m_Types[i].m_szName == type  )
				return m_Types[i].m_iFlag;

		}

		return 0;
	}

	int parseTypes ( array<string> types )
	{
		int flags = 0;

		for ( uint i = 0; i < types.length(); i ++  )
		{
			flags |= findTypeFlag(types[i]);
		}
	}
}

WptColor@ PathColor = WptColor(255,255,255,200);

// apparently "Waypoint" is a reserved class name
class CWaypoint
{
	// link to waypoint id
	array<int> m_PathsFrom;
	array<int> m_PathsTo;

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


	void draw ( CBasePlayer@ pPlayer, bool drawPaths )
	{

		drawBeam(pPlayer,m_vOrigin-Vector(0,0,32),m_vOrigin+Vector(0,0,32),g_WaypointTypes.getColour(m_iFlags));

		if ( drawPaths )
		{
			for ( uint i = 0; i < m_PathsTo.length(); i ++ )
			{
				CWaypoint@ wpt = g_Waypoints.getWaypointAtIndex(m_PathsTo[i]);
				
				drawBeam(pPlayer,m_vOrigin,wpt.m_vOrigin,PathColor);
			}
		}
	}

	
	float distanceFrom ( Vector vecLocation )
	{
		return (m_vOrigin - vecLocation).Length();
	}

	int numPaths ( )
	{
		return m_PathsTo.length();
	}

	void addPath ( int wpt )
	{
		m_PathsTo.insertLast(wpt);
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


CWaypoint@ ReadWaypoint ( int index, string line )
{
	array<string> csv = line.Split(",");

	Vector vecLoc;
	int iFlags;

	vecLoc.x = atof(csv[0]);
	vecLoc.y = atof(csv[1]);
	vecLoc.z = atof(csv[2]);
	iFlags = atoi(csv[3]);

	CWaypoint@ wpt = CWaypoint();

	wpt.Place(index, vecLoc);
	wpt.m_iFlags = iFlags;

	return wpt;
}	

class CWaypoints
{
	// Max waypoint is 1024 
	private array<CWaypoint> m_Waypoints(MAX_WAYPOINTS);

	bool g_WaypointsOn = false;
	int m_iNumWaypoints = 0;
	int m_PathFrom;

	CWaypoint@ getWaypointAtIndex ( uint idx )
	{
		return m_Waypoints[idx];
	}

	void WaypointsOn ( bool on )
	{
		g_WaypointsOn = on;

		if ( on )
			BotMessage("Waypoints On");
		else 
			BotMessage("Waypoints OFf");
	}

	void PathWaypoint_Create1 ( CBasePlayer@ player )
	{
		int wpt = getNearestWaypointIndex(player.pev.origin);

		BotMessage("Nearest waypoint is " + wpt + "\n");

		m_PathFrom = wpt;
	}

	void PathWaypoint_Create2 ( CBasePlayer@ player )
	{
		int wpt = getNearestWaypointIndex(player.pev.origin);

		BotMessage("Nearest waypoint is " + wpt + "\n");

		if ( wpt != -1 && m_PathFrom != -1 )
		{
			CWaypoint@ pWpt = getWaypointAtIndex(m_PathFrom);

			pWpt.addPath(wpt);
		}
	}


	void DrawWaypoints ( CBasePlayer@ player )
	{
		if ( g_WaypointsOn )
		{
			for ( int i = 0; i < m_iNumWaypoints; i ++ )
			{
				CWaypoint@ wpt = m_Waypoints[i];

				float dist = wpt.distanceFrom(player.pev.origin);

				if ( dist < 512 )
				{

					wpt.draw(player,dist<64);
				}
			}
		}
	}	

	int getWaypointIndex ( CWaypoint@ pWpt )
	{
		return pWpt.iIndex;
	}
	
	void addWaypoint ( Vector vecLocation, int flags = 0 )
	{
		int index = freeWaypointIndex();

		BotMessage("Adding waypoint...");

		if ( index != -1 )
		{	
			m_Waypoints[index].Place(index,vecLocation);

			BotMessage("OK! index " + formatInt(index));
		
			if ( index == m_iNumWaypoints )
				m_iNumWaypoints++;	

				BotMessage("Num waypoints = "+m_iNumWaypoints);
		}
	}

	int freeWaypointIndex ()
	{
		for( int i = 0; i < MAX_WAYPOINTS; i ++ )
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
			
			if ( (nearestWptIdx == -1 ) || ( distance < minDistance) )
			{
				minDistance = distance;
				nearestWptIdx = i;
			}
		}
		
		return nearestWptIdx;
	}

	void deleteWaypoint ( int idx )
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
		bool ret = false;
		File@ f = g_FileSystem.OpenFile( "scripts/plugins/BotManager/" + g_Engine.mapname + ".wpt", OpenFile::READ);

		// Open the file in 'read' mode
		if( f !is null ) 
		{
			// Read the whole file into the string buffer

			ClearWaypoints();

			int index = 0;

			string line;
			
			f.ReadLine(line);

			m_iNumWaypoints = atoi(line);

			while(!f.EOFReached())
			{
				
				f.ReadLine(line);

				CWaypoint@ wpt = ReadWaypoint(index,line);

				if ( wpt !is null )
				{
					m_Waypoints.insertLast(wpt);		
					ret = true;		
				}
			}

			f.Close();
		}

		return ret;
	}

	bool Save ()
	{
		bool ret = false;
		File@ f = g_FileSystem.OpenFile( "scripts/plugins/BotManager/" + g_Engine.mapname + ".wpt", OpenFile::WRITE);
		// Open the file in 'read' mode
		if( f !is null ) 
		{
			f.Write(formatInt(m_iNumWaypoints));

			for ( int i = 0; i < m_iNumWaypoints; i ++ )
			{
				CWaypoint@ wpt = m_Waypoints[i];
			
				f.Write(wpt.getSerialized());

				ret = true;
			}

			f.Close();
		}

		return ret;
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
			@curr = paths[iStart];
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
			@m_Head = newNode;
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