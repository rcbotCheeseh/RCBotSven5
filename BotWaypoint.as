
#include "FileBuffer"
#include "UtilFuncs"
#include "CBotBits"

CWaypoints g_Waypoints;
CWaypointTypes g_WaypointTypes;

const int W_FL_TEAM	= ((1<<0) + (1<<1));  /* allow for 4 teams (0-3) */
const int W_FL_TEAM_SPECIFIC = (1<<2);  /* waypoint only for specified team */
const int W_FL_CROUCH	= 	(1<<3);  /* must crouch to reach this waypoint */
const int W_FL_LADDER	= 	(1<<4);  /* waypoint on a ladder */
const int W_FL_LIFT		= 	(1<<5);  // lift button
const int W_FL_DOOR		= 	(1<<6);  /* wait for door to open */
const int W_FL_HEALTH	= 	(1<<7);  /* health kit (or wall mounted) location */
const int W_FL_ARMOR	= 	(1<<8);  /* armor (or HEV) location */
const int W_FL_AMMO		=	(1<<9);  /* ammo location */
const int W_FL_CHECK_LIFT	= (1<<10); /* checks for lift at this point */
const int W_FL_IMPORTANT	= (1<<11);/* flag position (or hostage or president) */
const int W_FL_DYNAMIC_TELEPORTER= ((1<<22)&(1<<21)); /* created automatically */
const int W_FL_SCIENTIST_POINT= (1<<11);
const int W_FL_TFC_FLAG_POINT=  (1<<11);
const int W_FL_BARNEY_POINT  = (1<<12);
const int W_FL_DEFEND_ZONE  =  (1<<13);
const int W_FL_AIMING	= (1<<14); /* aiming waypoint */
const int W_FL_CROUCHJUMP= 	(1<<16); // }
const int W_FL_WAIT_FOR_LIFT= (1<<17);/* wait for lift to be down before approaching this waypoint */
const int W_FL_PAIN	= (1<<18);
const int W_FL_JUMP    = (1<<19);
const int W_FL_WEAPON	= (1<<20); // Crouch and jump
const int W_FL_TELEPORT  = (1<<21);
const int W_FL_TANK	= (1<<22); // func_tank near waypoint
const int W_FL_FLY = (1<<23);
const int W_FL_GRAPPLE = (1<<23);
const int W_FL_STAY_NEAR= (1<<24);
const int W_FL_ENDLEVEL  = (1<<25); // end of level, in svencoop etc
const int W_FL_OPENS_LATER  =(1<<26);
const int W_FL_HUMAN_TOWER = (1<<27);// bot will crouch & wait for a player to jump on them
const int W_FL_UNREACHABLE = (1<<28); // not reachable by bot, used as a reference point for visibility only
const int W_FL_PUSHABLE  = (1<<29);
const int W_FL_GREN_THROW  = (1<<30);
const int W_FL_SNIPE = (1<<30);
const int W_FL_DELETED = (1<<31); /* used by waypoint allocation code */

const int MAX_WAYPOINTS = 1024;

void drawBeam (CBasePlayer@ pPlayer, Vector start, Vector end, WptColor@ col, int life = 10 )
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
	message.WriteByte( life ); // life in 0.1's
	message.WriteByte( 32 ); // width
	message.WriteByte( 2 );  // noise

	message.WriteByte( col.r );   // r, g, b
	message.WriteByte( col.g );   // r, g, b
	message.WriteByte( col.b );   // r, g, b

	message.WriteByte( col.a );   // brightness
	message.WriteByte( 1 );    // speed
	message.End();
}

class CWaypointHeader
{
	// 8 characters
   string filetype;  // should be "RC_bot\0"
   int  waypoint_file_version;
   int  waypoint_file_flags;  // used for visualisation
   int  number_of_waypoints;
   // 32 characters
   string mapname;  // name of map for these waypoints
	
	void Read ( FileBuffer@ file )
	{
		filetype = file.ReadString(8);
		BotMessage(filetype+"\n");
		waypoint_file_version = file.ReadInt32();
		BotMessage("VERSION = " + formatInt(waypoint_file_version)+"\n");
		waypoint_file_flags = file.ReadInt32();
		BotMessage("FLAGS = " + formatInt(waypoint_file_flags)+"\n");
		number_of_waypoints = file.ReadInt32();
		BotMessage("NUM WPTS = " + formatInt(number_of_waypoints)+"\n");

		mapname = file.ReadString(32);
	}

	CWaypointHeader ( )
	{
		filetype = "RCBot";
		waypoint_file_version = 10;
		waypoint_file_flags = 0;
		number_of_waypoints = g_Waypoints.m_iNumWaypoints;
	}


	void Save ( FileBuffer@ file )
	{
		file.Write(filetype,8);
		file.Write(waypoint_file_version);
		file.Write(waypoint_file_flags);
		file.Write(number_of_waypoints);
		file.Write(mapname,32);
	}
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
		m_Types.insertLast(CWaypointType("end",W_FL_ENDLEVEL,WptColor(255,0,255)));
		m_Types.insertLast(CWaypointType("ammo",W_FL_AMMO,WptColor(50,255,50)));
		m_Types.insertLast(CWaypointType("health",W_FL_HEALTH,WptColor(255,50,50)));
		m_Types.insertLast(CWaypointType("armor",W_FL_ARMOR,WptColor(255,255,0)));
		m_Types.insertLast(CWaypointType("openslater",W_FL_OPENS_LATER,WptColor(200,200,255)));
	}

	void printInfo ( CBasePlayer@ player, int flags )
	{
		string szflags = "";

		for ( uint i = 0; i < m_Types.length(); i ++ )
		{
			if ( flags & m_Types[i].m_iFlag == m_Types[i].m_iFlag )
				szflags += "," + m_Types[i].m_szName;
		}

		if ( szflags == "" )
			szflags = "NO FLAGS";

		SayMessage(player,szflags);
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

		return flags;
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
	int m_iFlags;
	
	CWaypoint ()
	{
		m_iFlags = 0;
	}

	bool hasFlags ( int flags )
	{
		return m_iFlags & flags == flags;
	}

	void Read ( FileBuffer@ file, int index )
	{
		m_iFlags = file.ReadInt32();
		BotMessage("m_iFlags = " + m_iFlags + "\n");
		m_vOrigin.x = file.ReadFloat();		
		m_vOrigin.y = file.ReadFloat();
		m_vOrigin.z = file.ReadFloat();

		BotMessage("m_vOrigin.x = " + m_vOrigin.x + "\n");
		BotMessage("m_vOrigin.y = " + m_vOrigin.y + "\n");
		BotMessage("m_vOrigin.z = " + m_vOrigin.z + "\n");

		int numPaths = file.ReadInt32();
		BotMessage("numPaths = " + numPaths + "\n");
		m_PathsTo = {};

		for (int i = 0; i < numPaths; i ++ )
			m_PathsTo.insertLast(file.ReadInt32());

		iIndex = index;
	}

	void Save ( FileBuffer@ file )
	{
		file.Write(m_iFlags);
		file.Write(m_vOrigin.x);
		file.Write(m_vOrigin.y);
		file.Write(m_vOrigin.z);
		file.Write(m_PathsTo.length());

		for ( uint i = 0; i < m_PathsTo.length(); i ++ )
		{
			file.Write(m_PathsTo[i]);
		}
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
		Clear();

		m_iFlags = W_FL_DELETED;
	}

	void Place ( int index, Vector loc )
	{
		m_vOrigin = loc;
		
		iIndex = index;
	}

	void Clear ()
	{
		m_PathsFrom = {};
		m_PathsTo = {};
		
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

const int W_VIS_RUNNING = 0;
const int W_VIS_COMPLETE = 1;

final class CWaypointVisibility
{
	int state;
	int iWptFrom;
	int iWptTo;	
	int iMaxLoops = 200;
	int m_iNumWaypoints;

	CBits@ bits;

	CWaypointVisibility ( int iNumWaypoints )
	{
		BotMessage("SET STATE");
		state = W_VIS_RUNNING;
		iWptFrom = 0;
		iWptTo = 0;
		@bits = CBits(MAX_WAYPOINTS*MAX_WAYPOINTS);		
		m_iNumWaypoints = iNumWaypoints;
	}

	bool VisibleFromTo ( int iFrom, int iTo )
	{
		int bit_num = (iFrom * m_iNumWaypoints) + iTo;
		
		return bits.getBit(bit_num);
	}

	int run ( )
	{

		if ( state == W_VIS_RUNNING )
		{
			int iLoops = 0;

			int Percent = (100 * ((iWptFrom * m_iNumWaypoints) + iWptTo)) / (m_iNumWaypoints * m_iNumWaypoints);

			BotMessage("Visibility Calculating Percent = " + Percent + " complete" );

			while ( (iLoops < iMaxLoops) && (state == W_VIS_RUNNING) )
			{				
					//@set_bits = null;
					//BotMessage(" " + iWptFrom + " / " + m_iNumWaypoints);

				if ( iWptFrom < m_iNumWaypoints )
				{					
					//BotMessage("iWptFrom < m_iNumWaypoints");

					if ( iWptTo >= m_iNumWaypoints )	
					{
						//BotMessage("iWptTo >= m_iNumWaypoints");
							iWptFrom++;
							iWptTo = 0;
					}
					else
					{
						//BotMessage("else");
						CWaypoint@ pFrom = g_Waypoints.getWaypointAtIndex(iWptFrom);
						CWaypoint@ pTo = g_Waypoints.getWaypointAtIndex(iWptTo);

						if ( !pFrom.hasFlags(W_FL_DELETED) && !pTo.hasFlags(W_FL_DELETED) )
						{
							int bit_num = (iWptFrom * MAX_WAYPOINTS) + iWptTo;
							
							bool bVisible =  UTIL_IsVisible ( pFrom.m_vOrigin, pTo.m_vOrigin, null );

							bits.setBit(bit_num,bVisible);																			
						}

						iWptTo ++;
					}
				}
				else
				{
					state = W_VIS_COMPLETE;
					//@set_bits = null;

				}

				iLoops++;
			}
		}

		return state;
	}
}

class CWaypoints
{
	// Max waypoint is 1024 
	private array<CWaypoint> m_Waypoints(MAX_WAYPOINTS);

	bool g_WaypointsOn = false;
	int m_iNumWaypoints = 0;
	int m_PathFrom;

	CWaypointVisibility@ m_VisibilityTable = null;

	CWaypoint@ getWaypointAtIndex ( uint idx )
	{
		return m_Waypoints[idx];
	}

	void runVisibility ()
	{
		if ( m_VisibilityTable !is null )
		{
			m_VisibilityTable.run();
	
		}
	

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
		int wpt = getNearestWaypointIndex(player.pev.origin,player);

		BotMessage("Nearest waypoint is " + wpt + "\n");

		m_PathFrom = wpt;
	}

	void PathWaypoint_Create2 ( CBasePlayer@ player )
	{
		int wpt = getNearestWaypointIndex(player.pev.origin,player);

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

				CWaypoint@ added = getWaypointAtIndex(index);
				// auto path waypoint
				for ( int i = 0; i < m_iNumWaypoints; i ++ )
				{
					CWaypoint@ other = getWaypointAtIndex(i);
					float zDiff = other.m_vOrigin.z - added.m_vOrigin.z;

					if ( zDiff < 0 )
						zDiff = -zDiff;

					if ( i == index )
						continue;					

					if ( added.distanceFrom(other.m_vOrigin) > 512 )
						continue;

					if ( zDiff > 64 )
					{
						continue;
					}
					
					if ( !UTIL_IsVisible(other.m_vOrigin,added.m_vOrigin) )
					{
						continue;
					}

					BotMessage("ADDED PATH\n");

					other.addPath(index);
					added.addPath(i);
				}
		}
	}

	int freeWaypointIndex ()
	{
		for( int i = 0; i < MAX_WAYPOINTS; i ++ )
		{
			if ( (m_Waypoints[i].m_iFlags & W_FL_DELETED) == W_FL_DELETED )
				return int(i);
		}

		if ( m_iNumWaypoints < MAX_WAYPOINTS )
			return m_iNumWaypoints;

		return -1;
	}

	void WaypointInfo ( CBasePlayer@ player )
	{
		int index = getNearestWaypointIndex(player.pev.origin,player);

		if ( index != -1 ) 
		{
			CWaypoint@ wpt = m_Waypoints[index];

			g_WaypointTypes.printInfo(player,wpt.m_iFlags);
		}
	}

	int getNearestFlaggedWaypoint ( CBasePlayer@ player, int iFlags )
	{
		int iIndex = -1;
		float min_distance = 0;
		
		for( int i = 0; i < m_iNumWaypoints; i ++ )
		{
			if ( m_Waypoints[i].m_iFlags & W_FL_DELETED == W_FL_DELETED )
				continue;	

			if ( m_Waypoints[i].m_iFlags & iFlags == iFlags )
			{
				float distance = m_Waypoints[i].distanceFrom(player.pev.origin);

				if ( iIndex == -1 || distance < min_distance )
				{
					min_distance = distance;
					iIndex = i;
				}
			}
		}
		
		return iIndex;
	}
	
	int getRandomFlaggedWaypoint ( int iFlags )
	{
		array<int> wpts;
		
		for( int i = 0; i < m_iNumWaypoints; i ++ )
		{
			if ( m_Waypoints[i].m_iFlags & W_FL_DELETED == W_FL_DELETED )
				continue;	

			if ( m_Waypoints[i].m_iFlags & iFlags == iFlags )
			{
				wpts.insertLast(i);
			}
		}
		
		if ( wpts.length() == 0 )
			return -1;

		return wpts[Math.RandomLong( 0, wpts.length()-1 )];
	}

	int getNearestWaypointIndex ( Vector vecLocation, CBasePlayer@ player = null, int iIgnore = -1 )
	{
		int nearestWptIdx = -1;
		float distance = 0;
		float minDistance = 0;
		
		for( int i = 0; i < m_iNumWaypoints; i ++ )
		{
			if ( i == iIgnore )
				continue;

			distance = m_Waypoints[i].distanceFrom(vecLocation);
			
			if ( (nearestWptIdx == -1 ) || ( distance < minDistance) )
			{
				if ( UTIL_IsVisible(vecLocation,m_Waypoints[i].m_vOrigin,player) )
				{
					minDistance = distance;
					nearestWptIdx = i;
				}
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

		if ( m_iNumWaypoints > 0 )
		{
			CWaypoint@ pDelete = g_Waypoints.getWaypointAtIndex(idx);

			pDelete.Delete();

			if ( idx == m_iNumWaypoints )
				m_iNumWaypoints--;
		}
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
		string filename = "scripts/plugins/BotManager/rcw/" + g_Engine.mapname + ".rcwa";
		File@ f = g_FileSystem.OpenFile( filename, OpenFile::READ);

		// Open the file in 'read' mode
		if( f !is null ) 
		{
			FileBuffer buf(f);
			// Read the whole file into the string buffer

			ClearWaypoints();

			int index = 0;

			CWaypointHeader@ hdr = CWaypointHeader();

			hdr.Read(buf);

			BotMessage("Waypoint Header : " + hdr.number_of_waypoints + "\n");

			//if ( hdr !is null )
			//	return false;

			for ( int i = 0; i < hdr.number_of_waypoints ; i ++ )
			{
				m_Waypoints[i].Read(buf,i);
			}

			BotMessage("Num Waypoints = " + hdr.number_of_waypoints);
			m_iNumWaypoints = hdr.number_of_waypoints;

			@m_VisibilityTable = CWaypointVisibility(m_iNumWaypoints);

			f.Close();
		}
		else
			BotMessage("Waypoint " + filename + " not found \n");

		return ret;
	}

	bool Save ()
	{
		bool ret = false;
		string filename = "scripts/plugins/BotManager/rcw/" + g_Engine.mapname + ".rcwa";
		File@ f = g_FileSystem.OpenFile( filename, OpenFile::WRITE);
		// Open the file in 'read' mode
		if( f !is null ) 
		{
			CWaypointHeader@ hdr = CWaypointHeader();

			FileBuffer buf;

			hdr.Save(buf);			
			
			for ( int i = 0; i < m_iNumWaypoints; i ++ )
			{
				m_Waypoints[i].Save(buf);
			}

			f.Write(buf.getData());

			f.Close();
		}
		else
			BotMessage("F is null!\n");

		return ret;
	}
}

class RCBotWaypointSorter
{
	void add ( int index, Vector vHideFrom )
	{
		int iInsertInto = m_pWaypoints.length;
		CWaypoint@ other = g_Waypoints.getWaypointAtIndex(index);

		for ( uint i = 0; i < m_pWaypoints.length; i ++ )
		{
			CWaypoint@ inList = m_pWaypoints[i];

			if ( other.distanceFrom(vHideFrom) > inList.distanceFrom(vHideFrom) )
			{
				iInsertInto = i;
				break;
			}
		}

		m_pWaypoints.insertAt(iInsertInto,other);
	}

	array<CWaypoint@> m_pWaypoints;

}

final class RCBotCoverWaypointFinder
{
	int iStart;

	int iDepth = 0;
	Vector vHideFrom;
	int iMaxDepth = 12;
	int iHideFrom;
	CBits@ closedWaypoints;
	CWaypointVisibility@ m_visibility;
	int state;
	int m_iGoalWaypoint;

	RCBotCoverWaypointFinder ( CWaypointVisibility@ visibility, RCBot@ bot, CBaseEntity@ hideFrom ) 
	{
		if ( visibility is null )
		{
			state = NavigatorState_Fail;
			return;
		}
		
		iStart = g_Waypoints.getNearestWaypointIndex(bot.origin(),bot.m_pPlayer,bot.m_iLastFailedWaypoint);
		vHideFrom = hideFrom.pev.origin;
		iHideFrom = g_Waypoints.getNearestWaypointIndex(vHideFrom);

		if ( iHideFrom != -1 || iStart == -1 )
		{
			state = NavigatorState_InProgress;

			@m_visibility = visibility;

			@closedWaypoints = CBits(MAX_WAYPOINTS);
		}
		else
			state = NavigatorState_Fail;
	}

	/**
	 * FindCover
	 *
	 * Recursive function
	 */
	int FindCover ( int iWaypoint )
	{
		iDepth++;

		if ( iDepth > iMaxDepth )
			return -1;

		if (m_visibility.VisibleFromTo(iHideFrom,iWaypoint) == false )
			return iWaypoint;
		else
		{
			CWaypoint@ wpt = g_Waypoints.getWaypointAtIndex(iWaypoint);
			closedWaypoints.setBit(iWaypoint,true);

			RCBotWaypointSorter@ paths = RCBotWaypointSorter();

			for ( int i = 0; i < wpt.numPaths(); i ++ )
			{			
				int iWptIndex = wpt.getPath(i);

				if ( closedWaypoints.getBit(iWptIndex) == false )
				{
					paths.add(iWptIndex,vHideFrom);		
				}
			}

			for ( uint i = 0; i < paths.m_pWaypoints.length(); i ++ )
			{
				CWaypoint@ pWpt = paths.m_pWaypoints[i];

				int iWptIndex = pWpt.iIndex;

				if ( FindCover(iWptIndex) == iWptIndex )
				{
					return iWptIndex;
				}			
			}
		}
	
		return -1;
	}

	bool execute ( )
	{
		BotMessage("FINDING COVER!!!!");

		m_iGoalWaypoint = FindCover(iStart);

		return m_iGoalWaypoint != -1;
	}

}

	const int NavigatorState_Complete = 0;
	const int NavigatorState_InProgress = 1;
	const int NavigatorState_Fail = 2;
	const int NavigatorState_ReachedGoal = 3;
	const int NavigatorState_FoundGoal = 4;
	const int NavigatorState_Following = 5;
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

	float m_fNextTimeout;

	int m_iCurrentWaypoint = -1;

	array<AStarNode> paths(MAX_WAYPOINTS);
	AStarNode@ curr;

	CWaypoint@ pStartWpt;
	CWaypoint@ pGoalWpt;

	AStarOpenList m_theOpenList;

	void open ( AStarNode@ pNode )
	{
		if ( pNode.isOpen() == false )
		{
			pNode.open();
			//m_theOpenList.push_back(pNode);
			m_theOpenList.add(pNode);
		}
	}

	// AStar Algorithm : get the waypoint with lowest cost
	AStarNode@ nextNode ()
	{
		AStarNode@ pNode = null;

		@pNode = m_theOpenList.top();
		m_theOpenList.pop();
			
		return pNode;
	}

	RCBotNavigator ( RCBot@ bot , int iGoalWpt )
	{
		m_iCurrentWaypoint = iStart = g_Waypoints.getNearestWaypointIndex(bot.m_pPlayer.pev.origin, bot.m_pPlayer,bot.m_iLastFailedWaypoint);
	m_fNextTimeout = 0;
		if ( iStart == -1 || iGoalWpt == -1 )
		{
			BotMessage("IsTART == -1 OR GOAL == -1");
			state = NavigatorState_Fail;
		}
		else
		{
			state = NavigatorState_InProgress;
			@curr = paths[iStart];
			curr.setWaypoint(iStart);
			@pStartWpt = g_Waypoints.getWaypointAtIndex(iStart);
			iGoal = iGoalWpt;
			@pGoalWpt = g_Waypoints.getWaypointAtIndex(iGoal);


			curr.setHeuristic(0);
			open(curr);
			iLastNode = iStart;
		}
	}	

	RCBotNavigator ( RCBot@ bot , Vector vTo )
	{
		m_iCurrentWaypoint = iStart = g_Waypoints.getNearestWaypointIndex(bot.m_pPlayer.pev.origin, bot.m_pPlayer);
		iGoal = g_Waypoints.getNearestWaypointIndex(vTo);
m_fNextTimeout = 0;
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

	bool execute ( RCBot@ bot )
	{
		if ( m_fNextTimeout < g_Engine.time )
		{
			bot.m_iLastFailedWaypoint = m_iCurrentWaypoint;
			return false;
		}
	
		if ( m_currentRoute.length () == 0 )
		{			
			return false;
		}

		m_iCurrentWaypoint = m_currentRoute[0];

		CWaypoint@ wpt = g_Waypoints.getWaypointAtIndex(m_iCurrentWaypoint);

		if ( (wpt.m_vOrigin - bot.origin()).Length() < 100 )
		{
			bot.touchedWpt(wpt);

			m_fNextTimeout = g_Engine.time + 5.0;

			m_currentRoute.removeAt(0);

			if ( m_currentRoute.length () == 0 )
			{
				state = NavigatorState_ReachedGoal;				
				return true;
			}
		}
		else
		{
			bot.followingWpt(wpt);
			
		}	

		return false;
	}

	int iCurrentNode = -1;

	array<int> m_currentRoute = {};

	int run ()
	{		
		switch ( state )
		{
			case NavigatorState_InProgress:
			{
						int iLoops = 0;
		int iPath;

		//BotMessage("Navigator State IN_PROGRESS...\n");

						while ( state == NavigatorState_InProgress )
						{
							iLoops++;


							if ( m_theOpenList.empty() )
							{
								//BotMessage("EMPTY OPEN LIST");
								state = NavigatorState_Fail;
								break;
							}							

							@curr = nextNode();


							if ( @curr is null )
							{
								//BotMessage("CURR NULL");
								state = NavigatorState_Fail;
								break;
							}

							if ( iLoops > iMaxLoops )
								break;


							if ( curr.getWaypoint() == iGoal )
							{
								state = NavigatorState_FoundGoal;
								break;
							}

							CWaypoint@ currWpt = g_Waypoints.getWaypointAtIndex(curr.getWaypoint());
							CWaypoint@ succWpt;
							AStarNode@ succ;

							iCurrentNode = curr.getWaypoint();
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
								@succWpt = g_Waypoints.getWaypointAtIndex(iSucc);

								if ( succWpt.hasFlags(W_FL_OPENS_LATER) )
								{
									// make sure path is visible from current to succ
									if ( !UTIL_IsVisible(currWpt.m_vOrigin,succWpt.m_vOrigin) )
										continue;
								}

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
			}		
			break;
			case NavigatorState_FoundGoal:
			{
					int iLoops = 0;

					float fDistance = 0.0;
					int iParent;

					m_fNextTimeout = g_Engine.time + 5.0;

					m_currentRoute.insertAt(0,iGoal);

					while ( (iCurrentNode != -1) && (iCurrentNode != m_iCurrentWaypoint ) && (iLoops <= g_Waypoints.m_iNumWaypoints) )
					{
						iLoops++;

						m_currentRoute.insertAt(0,iCurrentNode);

						iParent = paths[iCurrentNode].getParent();

						iCurrentNode = iParent;
					}

					if ( m_currentRoute.length () > 0 )
					{
						m_iCurrentWaypoint = m_currentRoute[0];

					}
					else
					{
						// error
						//BotMessage("ERORRR");
						state = NavigatorState_Fail;
						break;
					}

					state = NavigatorState_Following;

					BotMessage("Navigator State FOUND_GOAL...\n");
			}
			break;
			default:

				//BotMessage("Current Waypoint =	 " +  m_iCurrentWaypoint + " - goal =  " + iGoal+"");
			break;
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