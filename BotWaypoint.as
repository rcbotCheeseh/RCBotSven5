
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
const int W_FL_BARNEY_POINT  = (1<<12);
const int W_FL_DEFEND_ZONE  =  (1<<13);
const int W_FL_AIMING	= (1<<14); /* aiming waypoint */
const int W_FL_CROUCHJUMP = 	(1<<16); // }	
const int W_FL_WAIT = (1<<17);/* wait for lift to be down before approaching this waypoint */
const int W_FL_PAIN	= (1<<18);
const int W_FL_JUMP    = (1<<19);
const int W_FL_WEAPON	= (1<<20); // Crouch and jump
const int W_FL_TELEPORT  = (1<<21);
const int W_FL_TANK	= (1<<22); // func_tank near waypoint
const int W_FL_GRAPPLE = (1<<23);
const int W_FL_STAY_NEAR = (1<<24);
const int W_FL_ENDLEVEL  = (1<<25); // end of level, in svencoop etc
const int W_FL_OPENS_LATER  =(1<<26);
const int W_FL_HUMAN_TOWER = (1<<27);// bot will crouch & wait for a player to jump on them
const int W_FL_UNREACHABLE = (1<<28); // not reachable by bot, used as a reference point for visibility only
const int W_FL_PUSHABLE  = (1<<29);
const int W_FL_GREN_THROW  = (1<<30);
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
	
	bool Read ( FileBuffer@ file )
	{
		filetype = file.ReadString(8);
		BotMessage("FILETYPE = " + filetype);
		waypoint_file_version = file.ReadInt32();
		BotMessage("VERSION = " + formatInt(waypoint_file_version));
		waypoint_file_flags = file.ReadInt32();
		BotMessage("FLAGS = " + formatInt(waypoint_file_flags));
		number_of_waypoints = file.ReadInt32();
		BotMessage("NUM WPTS = " + formatInt(number_of_waypoints));

		mapname = file.ReadString(32);		
		BotMessage("MAPNAME = " + mapname);

		return number_of_waypoints < MAX_WAYPOINTS;
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
		int flag = 1;

		for ( int r = 250; r >= 50; r -= 50 )
		{
			for ( int g = 250; g >= 50; g -= 50 )
			{
				for ( int b = 250; b >= 50; b -= 50 )
				{
					WptColor color = WptColor(r,g,b);
					string name = "";

					switch ( flag )
					{
						case W_FL_TEAM :
							name = "team";
							break;
						case W_FL_TEAM_SPECIFIC :
							name = "teamspecific";
							break;
						case W_FL_CROUCH :
							name = "crouch";
							break;
						case W_FL_LADDER :
						name = "ladder";
						break;
						case W_FL_LIFT :
						name = "lift";
						break;
						case W_FL_DOOR :
						name = "door";
						break;
						case W_FL_HEALTH :
						name = "health";
						break;
						case W_FL_ARMOR :
						name = "armor";
						break;
						case W_FL_AMMO :
						name = "ammo";
						break;
						case W_FL_CHECK_LIFT :
						name = "checklift";
						break;
						case W_FL_IMPORTANT :
						name = "important";
						break;
						case W_FL_BARNEY_POINT :
						name = "barney";
						break;
						case W_FL_DEFEND_ZONE :
						name = "defend";
						break;
						case W_FL_AIMING :
						name = "aiming";
						break;
						case W_FL_CROUCHJUMP :
						name = "crouchjump";
						break;
						case W_FL_WAIT :
						name = "wait";
						break;
						case W_FL_PAIN :
						name = "pain";
						break;
						case W_FL_JUMP :
						name = "jump";
						break;
						case W_FL_WEAPON :
						name = "weapon";
						break;
						case W_FL_TELEPORT :
						name = "teleport";
						break;
						case W_FL_TANK :
						name = "tank";
						break;
						case W_FL_GRAPPLE :
						name = "grapple";
						break;
						case W_FL_STAY_NEAR :
						name = "staynear";
						break;
						case W_FL_ENDLEVEL :
						name = "end";
						break;
						case W_FL_OPENS_LATER :
						name = "openslater";
						break;
						case W_FL_HUMAN_TOWER :
						name = "humantower";
						break;
						case W_FL_UNREACHABLE :
						name = "unreachable";
						break;
						case W_FL_PUSHABLE :
						name = "pushable";
						break;
						case W_FL_GREN_THROW :
						name = "grenthrow";
						break;
						case W_FL_DELETED :
						name = "deleted";
						break;
						default:
						break;
					}

					if ( name != "" )
					{
						m_Types.insertLast(CWaypointType(name,flag,color));
						BotMessage("Added waypoint type ("+name+","+flag+")");
					}
					// finished
					if ( flag == W_FL_DELETED )
					{
						return;
					}
					else 
						flag *= 2;
				}
			}
		}

		//m_Types.insertLast(CWaypointType("button",W_FL_BUTTON,WptColor(200,200,255)));
	}

	void printInfo ( CBasePlayer@ player, int flags )
	{
		string szflags = "";

		for ( uint i = 0; i < m_Types.length(); i ++ )
		{
			//BotMessage("Searching Types in flags " + flags + "... against " + m_Types[i].m_iFlag );

			if ( (flags & m_Types[i].m_iFlag) == m_Types[i].m_iFlag )
			{
				szflags += "," + m_Types[i].m_szName;
			}
		}

		if ( szflags == "" )
			szflags = "NO FLAGS";
		//BotMessage(szflags);
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
			//BotMessage("FindTypeFlag('"+type+") against '"+m_Types[i].m_szName+"'" );
			if ( m_Types[i].m_szName == type  )
			{
				//BotMessage("FOUND returning "+ m_Types[i].m_iFlag);
				return m_Types[i].m_iFlag;
			}
		}

		return 0;
	}

	int parseTypes ( array<string> types )
	{
		int flags = 0;

		for ( uint i = 0; i < types.length(); i ++  )
		{
			int flag = findTypeFlag(types[i]);

			if ( flag != 0 )
			{
				flags |= findTypeFlag(types[i]);
				
			}
			else
				BotMessage("Waypoint type " + types[i]+" not found");
			
		}
		//BotMessage("parseTypes returning " + flags);
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

	void removePaths ()
	{
		m_PathsFrom = {};
		m_PathsTo = {};
	}

	bool hasFlags ( int flags )
	{
		return m_iFlags & flags == flags;
	}

	bool Read ( FileBuffer@ file, int index )
	{
		m_iFlags = file.ReadInt32();
		//BotMessage("m_iFlags = " + m_iFlags + "\n");
		m_vOrigin.x = file.ReadFloat();		
		m_vOrigin.y = file.ReadFloat();
		m_vOrigin.z = file.ReadFloat();

		//BotMessage("m_vOrigin.x = " + m_vOrigin.x + "\n");
		////BotMessage("m_vOrigin.y = " + m_vOrigin.y + "\n");
		//BotMessage("m_vOrigin.z = " + m_vOrigin.z + "\n");

		int numPaths = file.ReadInt32();

		m_PathsTo = {};
		iIndex = index;

		if ( numPaths < 32 )
		{
			//BotMessage("numPaths = " + numPaths + "\n");			

			for (int i = 0; i < numPaths; i ++ )
				m_PathsTo.insertLast(file.ReadInt32());

			return true;
		}
		else
			return false;
		
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

	void removePath ( int wpt )
	{
		int idx = m_PathsTo.find(wpt);

		if ( idx >= 0 )
			m_PathsTo.removeAt(idx);
	}

	void addPath ( int wpt )
	{
		if ( m_PathsTo.find(wpt) < 0 )
		{
			CWaypoint@ pwpt = g_Waypoints.getWaypointAtIndex(wpt);
			
			if ( pwpt.hasFlags(W_FL_DELETED) )
				return;

			if ( m_PathsTo.length() < 32 )
				m_PathsTo.insertLast(wpt);
		}
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
		m_iFlags = 0;
		iIndex = index;
	}

	void Clear ()
	{
		m_PathsFrom = {};
		m_PathsTo = {};
		
		m_iFlags = 0;
	}


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
		//BotMessage("SET STATE");
		state = W_VIS_RUNNING;
		iWptFrom = 0;
		iWptTo = 0;
		@bits = CBits(MAX_WAYPOINTS*MAX_WAYPOINTS);		
		m_iNumWaypoints = iNumWaypoints;
	}

	bool VisibleFromTo ( int iFrom, int iTo )
	{
		int bit_num = (iFrom * MAX_WAYPOINTS) + iTo;
		
		return bits.getBit(bit_num);
	}

	int run ( )
	{

		if ( state == W_VIS_RUNNING )
		{
			int iLoops = 0;

			int Percent = (100 * ((iWptFrom * m_iNumWaypoints) + iWptTo)) / (m_iNumWaypoints * m_iNumWaypoints);

			//BotMessage("Visibility Calculating Percent = " + Percent + " complete" );

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


	void PathWaypoint_Remove1 ( CBasePlayer@ player )
	{
		int wpt = getNearestWaypointIndex(player.pev.origin,player);

		BotMessage("Nearest waypoint is " + wpt + "\n");

		m_PathFrom = wpt;
	}

	void PathWaypoint_Remove2 ( CBasePlayer@ player )
	{
		int wpt = getNearestWaypointIndex(player.pev.origin,player);

		BotMessage("Nearest waypoint is " + wpt + "\n");

		if ( wpt != -1 && m_PathFrom != -1 )
		{
			CWaypoint@ pWpt = getWaypointAtIndex(m_PathFrom);

			pWpt.removePath(wpt);
		}
	}


	void DrawWaypoints ( CBasePlayer@ player )
	{
		if ( g_WaypointsOn )
		{
			CWaypoint@ pNearestWpt = null;
			float m_fNearest = 96;

			for ( int i = 0; i < m_iNumWaypoints; i ++ )
			{
				CWaypoint@ wpt = m_Waypoints[i];

				if ( wpt.m_iFlags & W_FL_DELETED == W_FL_DELETED )
					continue;					

				float dist = wpt.distanceFrom(player.pev.origin);

				if ( dist < m_fNearest )
				{
					@pNearestWpt = wpt;
					m_fNearest = dist;					
				}
				
				if ( dist < 512 )
					wpt.draw(player,false);
			}

			if ( pNearestWpt !is null )
				pNearestWpt.draw(player,true);
		}
	}	

	int getWaypointIndex ( CWaypoint@ pWpt )
	{
		return pWpt.iIndex;
	}
	
	void addWaypoint ( Vector vecLocation, int flags = 0, CBaseEntity@ ignore = null )
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
				
				TraceResult tr;

				if ( flags & W_FL_UNREACHABLE  != W_FL_UNREACHABLE )
				{
					// auto path waypoint
					for ( int i = 0; i < m_iNumWaypoints; i ++ )
					{
						CWaypoint@ other = getWaypointAtIndex(i);

						if ( other.hasFlags(W_FL_DELETED))
							continue;

						if ( other.hasFlags(W_FL_UNREACHABLE) )
							continue;

						if ( i == index )
							continue;					

						if ( added.distanceFrom(other.m_vOrigin) > 512 )
							continue;

						if ( (flags & W_FL_CROUCH != W_FL_CROUCH) && ( !other.hasFlags(W_FL_CROUCH)) )
						{
							g_Utility.TraceHull(added.m_vOrigin, other.m_vOrigin, ignore_monsters,human_hull,  ignore is null ? null : ignore.edict(), tr);
							
							if ( tr.flFraction < 1.0 ) // !UTIL_IsVisible(other.m_vOrigin,added.m_vOrigin) )
							{
								continue;
							}

						}
						else
						{
							if ( !UTIL_IsVisible(other.m_vOrigin,added.m_vOrigin) )
								continue;
						}

						//BotMessage("ADDED PATH\n");

						other.addPath(index);
						added.addPath(i);
					}

					CBaseEntity@ pent = null;
					
					while ( (@pent =  g_EntityFuncs.FindEntityByClassname(pent, "*")) !is null )
					{					
						string classname = pent.GetClassname();

						float dist = (added.m_vOrigin - UTIL_EntityOrigin(pent)).Length();

						if ( dist > 96 )
							continue;

						if ( pent.pev.owner is null )
						{					
							if ( classname.SubString(0,7) == "weapon_")
								flags |= W_FL_WEAPON;
							else if ( classname.SubString(0,5) == "ammo_")
								flags |= W_FL_AMMO;
							else if ( classname.SubString(0,11) == "item_health")
								flags |= W_FL_HEALTH;
							else if ( classname.SubString(0,12) == "item_battery")
								flags |= W_FL_ARMOR;
						}

						if ( classname.SubString(0,11) == "func_button")
							flags |= W_FL_IMPORTANT;
						else if ( classname.SubString(0,15) == "func_rot_button")
							flags |= W_FL_IMPORTANT;						
						else if ( classname.SubString(0,11) == "func_health" )
							flags |= W_FL_HEALTH;
						else if ( classname.SubString(0,13) == "func_recharge" )
							flags |= W_FL_ARMOR;
						else if ( classname.SubString(0,12) == "trigger_hurt" )
							flags |= W_FL_PAIN;			

						BotMessage(classname);
					}
				}


			m_Waypoints[index].m_iFlags = flags;

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
	
	int getRandomFlaggedWaypoint ( int iFlags, CFailedWaypointsList@ failed = null )
	{
		array<int> wpts;
		
		for( int i = 0; i < m_iNumWaypoints; i ++ )
		{
			if ( m_Waypoints[i].m_iFlags & W_FL_DELETED == W_FL_DELETED )
				continue;	

			if ( failed.contains(i) )
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

	void PathWaypoint_RemovePathsFrom ( int wpt )
	{
		CWaypoint@ pWpt = m_Waypoints[wpt];

		pWpt.removePaths();	
	}

	void PathWaypoint_RemovePathsTo ( int wpt )
	{
		for ( int i = 0; i < m_iNumWaypoints; i ++ )
		{
			CWaypoint@ pWpt = m_Waypoints[i];

			pWpt.removePath(wpt);
		}
	}

	int getNearestWaypointIndex ( Vector vecLocation, CBasePlayer@ player = null, int iIgnore = -1, float minDistance = 512.0f, bool bCheckVisible = true )
	{
		int nearestWptIdx = -1;
		float distance = 0;

		for( int i = 0; i < m_iNumWaypoints; i ++ )
		{
			if ( i == iIgnore )
				continue;

			if ( m_Waypoints[i].m_iFlags & W_FL_DELETED == W_FL_DELETED )
				continue;					

			distance = m_Waypoints[i].distanceFrom(vecLocation);
			
			if ( (nearestWptIdx == -1 ) || ( distance < minDistance) )
			{
				if ( !bCheckVisible || UTIL_IsVisible(vecLocation,m_Waypoints[i].m_vOrigin,player) )
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
		m_iNumWaypoints = 0 ;
		m_PathFrom = -1;
		@m_VisibilityTable = null;
	}

	bool Load ()
	{
		bool ret = false;
		string filename = g_Engine.mapname;
		
		File@ f;

		filename += ".rcwa";
		

		ClearWaypoints();

		// try to open custom waypoint first		
		@f  = g_FileSystem.OpenFile( "scripts/plugins/store/" + filename , OpenFile::READ);

		// no custom waypoint exists
		if ( @f is null )
		{
			// open default waypoint 
			@f = g_FileSystem.OpenFile( "scripts/plugins/BotManager/rcw/" + filename , OpenFile::READ);
		}

		// Open the file in 'read' mode
		if( f !is null ) 
		{
			FileBuffer buf(f);
			// Read the whole file into the string buffer

			ClearWaypoints();

			int index = 0;

			CWaypointHeader@ hdr = CWaypointHeader();

			if ( !hdr.Read(buf) )
			{
				f.Close();
				BotMessage("WAYPOINT FILE CORRUPT");
				return false;
			}

			BotMessage("Waypoint Header : " + hdr.number_of_waypoints + "\n");

			//if ( hdr !is null )
			//	return false;

			for ( int i = 0; i < hdr.number_of_waypoints ; i ++ )
			{
				if ( !m_Waypoints[i].Read(buf,i) )
				{
					BotMessage("WAYPOINT " + i + " CORRUPT!");
					return false;
				}
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
		string filename = "scripts/plugins/store/" + g_Engine.mapname + ".rcwa";
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
		// failed before we started
		if ( state == NavigatorState_Fail )
			return -1;

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

class CFailedWaypointsList
{
    void add ( int iwpt )
    {
        if ( !contains(iwpt) )
            list.insertLast(iwpt);
    }

    bool contains ( int iwpt )
    {
        return list.find(iwpt) >= 0;
    }

    void clear ()
    {
        list = {};
    }
	
    array<int> list;
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

	float m_fNextCheckVisible = 0.0;
	float m_fLastSeeWaypoint = 0.0;
	float m_fPreviousDistance = 9999;

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

		BotMessage("m_iCurrentWaypoint == " + m_iCurrentWaypoint);
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

	void execute ( RCBot@ bot )
	{
		if ( m_fNextTimeout < g_Engine.time )
		{
			BotMessage("m_fNextTimeout < g_Engine.time");
			bot.m_iLastFailedWaypoint = m_iCurrentWaypoint;
			state = NavigatorState_Fail;
			return;
		}
	
		if ( m_currentRoute.length () == 0 )
		{			
			BotMessage("m_currentRoute.length () == 0");
			state = NavigatorState_Fail;
			return;
		}

		m_iCurrentWaypoint = m_currentRoute[0];

		CWaypoint@ wpt = g_Waypoints.getWaypointAtIndex(m_iCurrentWaypoint);

		float distance = (wpt.m_vOrigin - bot.origin()).Length();

		float touch_distance = 64;

		if ( wpt.hasFlags(W_FL_JUMP) )
			touch_distance = 24;
		else if ( wpt.hasFlags(W_FL_STAY_NEAR) )
			touch_distance = 40;

		BotMessage("Current = " + m_iCurrentWaypoint + " , Dist = " + distance);

		if ( (distance < 64) || (distance > (m_fPreviousDistance+64.0)) )
		{
			bot.touchedWpt(wpt);

			m_fNextTimeout = g_Engine.time + 5.0;

			m_currentRoute.removeAt(0);

			m_fPreviousDistance = 9999.0;

			m_fLastSeeWaypoint = g_Engine.time;

			if ( m_currentRoute.length () == 0 )
			{
				state = NavigatorState_ReachedGoal;			
				BotMessage("m_currentRoute.length () == 0 ");			
				return;
			}
		}
		else
		{
			BotMessage("FOLLOWING");
			bot.followingWpt(wpt);
			m_fPreviousDistance = distance;

			if ( m_fNextCheckVisible < g_Engine.time )
			{
				m_fNextCheckVisible = g_Engine.time + 1.0;

        		TraceResult tr;

		        g_Utility.TraceLine( bot.m_pPlayer.pev.origin + bot.m_pPlayer.pev.view_ofs, wpt.m_vOrigin, ignore_monsters,dont_ignore_glass, bot.m_pPlayer.edict(), tr );

				if ( tr.flFraction >= 1.0 )				
					m_fLastSeeWaypoint = g_Engine.time;
				else if ( m_fLastSeeWaypoint > 0 && ((g_Engine.time - m_fLastSeeWaypoint) > 3.0) )
				{
					BotMessage("BotNavigator FAIL");
					m_fLastSeeWaypoint = 0;
					// Fail
					state = NavigatorState_Fail;
					return;
				}
				else
				{
					if ( tr.pHit !is null )
					{
						if ( tr.pHit.vars.targetname != "" )
						{
							CBaseEntity@ button = UTIL_FindEntityByTarget(null,tr.pHit.vars.targetname);

							if ( button !is null )
							{
								if ( button.GetClassname() == "func_button" )
								{
									// TO DO
									// add Schedule to press button


								}
							}
						}
					}
				}

			}
		}	

			return;
	}

	int iCurrentNode = -1;

	array<int> m_currentRoute = {};

	int run (RCBot@ bot)
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

							//	BotMessage("PATH FROM " + iCurrentNode + " TO " + iSucc);
								
								if ( iSucc == iLastNode ) // argh?
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

								if ( succWpt.hasFlags(W_FL_GRAPPLE) )
								{
									if ( !bot.HasWeapon("weapon_grapple") )	
										continue;
								}
								if ( succWpt.hasFlags(W_FL_OPENS_LATER) )
								{
									/*TraceResult tr;

									g_Utility.TraceLine( currWpt.m_vOrigin, succWpt.m_vOrigin, ignore_monsters,dont_ignore_glass, null, tr );

									if ( tr.flFraction < 1.0f )
									{
										if ( tr.pHit is null )
											continue;

										CBaseEntity@ pentArea;
										CBaseEntity@ pentActivator;
										string szClassname;
										eMasterType iMasterVal;

										if ( tr.pHit is null )
											continue; // hit something we can't check
										if ( tr.pHit.GetClassname() == "worldspawn" )
											continue; // hit a wall that can't be opened
										
										pentArea = g_EntityFuncs.Instance(tr.pHit);
									
										pentActivator = bot.m_pPlayer;
										
										if ( pentArea && pentActivator && !pentArea->IsTriggered(pentActivator) )
											continue; // it can't be opened yet..
										
										// get master value
										iMasterVal = gBotGlobals.m_Masters.EntityCanFire(tr.pHit,pBot->m_pEdict);
															
										switch ( iMasterVal )
										{
										case MASTER_NONE:
											// bot cant open it without using something?
											{
												char *szTargetname = (char*)STRING(tr.pHit->v.targetname);
												
												if ( szTargetname && *szTargetname )
												{
													edict_t *pTarget = UTIL_FindEntityByTarget(NULL,szTargetname);
														
													if ( pTarget )
													{
														if ( gBotGlobals.m_Masters.EntityCanFire(pTarget,pBot->m_pEdict) == MASTER_TRIGGERED )
															break;										
													}

													continue;
												}
											}
											break;
										case MASTER_FAULT:
										case MASTER_NOT_TRIGGERED:
											continue;
										case MASTER_TRIGGERED:
											break;
										default:
											break;

										}	
									}*/
																		
									TraceResult tr;

									g_Utility.TraceLine( currWpt.m_vOrigin, succWpt.m_vOrigin, ignore_monsters,dont_ignore_glass, null, tr );

									if ( tr.flFraction < 1.0f )
									{
										if ( tr.pHit is null )
											continue;
									
										CBaseEntity@ ent = g_EntityFuncs.Instance(tr.pHit);

										// mght be closed but is not locked
										if ( ent.GetClassname() == "func_door")
										{
											CBaseDoor@ door = cast<CBaseDoor@>( ent );

											if ( !UTIL_DoorIsOpen(door,bot.m_pPlayer) )
												continue;
										}
										else
											continue;
									}		
								}
								if ( succWpt.hasFlags(W_FL_PAIN) )
								{
				
									CBaseEntity@ pent = null;
									bool bFound = false;
									Vector vSucc = succWpt.m_vOrigin;

									while ( (@pent =  g_EntityFuncs.FindEntityByClassname(pent, "trigger_hurt")) !is null )
									//while ( (@pent = g_EntityFuncs.FindEntityInSphere(pent, succWpt.m_vOrigin , 128,"trigger_hurt", "classname"  )) !is null )
									{										
											if ( ((pent.pev.spawnflags & 8)!=8) && (pent.pev.solid == SOLID_TRIGGER) )
											{
												if ( UTIL_VectorInsideEntity(pent,vSucc) )
												{
													BotMessage("TRIGGET HURT DETECTED!!!");
													bFound = true;
													break;
												}
											}
									}

									if ( bFound )
										continue;
																	
								}

								//if ( (iSucc != m_iGoalWaypoint) && !m_pBot.canGotoWaypoint(vOrigin,succWpt,currWpt) )
							//		continue;

								float fCost = curr.getCost();
								
								if ( !currWpt.hasFlags(W_FL_TELEPORT) )
									fCost += (succWpt.distanceFrom(currWpt.m_vOrigin));

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
								//BotMessage("Succ " + iSucc + " parent = " + iCurrentNode);

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

					iCurrentNode = iGoal;

					while ( (iCurrentNode != -1) && (iCurrentNode != m_iCurrentWaypoint ) && (iLoops <= g_Waypoints.m_iNumWaypoints) )
					{
						iLoops++;

						m_currentRoute.insertAt(0,iCurrentNode);

						iParent = paths[iCurrentNode].getParent();

						iCurrentNode = iParent;
					}

					if ( iLoops < g_Waypoints.m_iNumWaypoints )
					{

						m_currentRoute.insertAt(0,m_iCurrentWaypoint);

						if ( m_currentRoute.length () > 0 )
						{
							m_iCurrentWaypoint = m_currentRoute[0];

							/*for ( uint i = 0; i < m_currentRoute.length(); i ++ )
							{
								BotMessage("ROUTE " + i + " - " + m_currentRoute[i]);
							}		*/				

							state = NavigatorState_Following;

							BotMessage("Navigator State FOUND_GOAL...\n");
						}
						else
						{

							// error
							//BotMessage("ERORRR");
							state = NavigatorState_Fail;
							break;
						}

					}
					else
					{
						state = NavigatorState_Fail;
					}

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