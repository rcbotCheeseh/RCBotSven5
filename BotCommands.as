
#include "BotManagerInterface"
#include "BotWaypoint"
#include "CBotTasks"
#include "UtilFuncs"
#include "BotWeapons"
#include "CBotBits"

CConCommand@ m_pRCBotWaypointConvertType;
CConCommand@ m_pAddBot;
CConCommand@ m_pRCBotWaypointAdd;
CConCommand@ m_pRCBotWaypointDelete;
CConCommand@ m_pRCBotWaypointInfo;
CConCommand@ m_pRCBotWaypointOff;
CConCommand@ m_pRCBotWaypointOn;
CConCommand@ m_pPathWaypointCreate1;
CConCommand@ m_pPathWaypointCreate2;
CConCommand@ m_pPathWaypointRemove1;
CConCommand@ m_pPathWaypointRemove2;
CConCommand@ m_pRCBotWaypointLoad;
CConCommand@ m_pRCBotWaypointSave;
CConCommand@ m_pRCBotWaypointClear;
CConCommand@ m_pRCBotSearch;
CConCommand@ GodMode;
CConCommand@ NoClipMode;
CConCommand@ m_pRCBotWaypointRemoveType;
CConCommand@ m_pRCBotWaypointGiveType;
CConCommand@ m_pDebugBot;
CConCommand@ m_pRCBotKillbots;
CConCommand@ m_pNotouchMode;
CConCommand@ m_pExplo;
CConCommand@ m_pNoTargetMode;
CConCommand@ m_pRCBotWaypointToggleType;
CConCommand@ m_pPathWaypointRemovePathsFrom;
CConCommand@ m_pPathWaypointRemovePathsTo;
CCVar@ m_pVisRevs;
CCVar@ m_pNavRevs;

bool g_DebugOn = false;
bool g_NoTouch = false;
bool g_NoTouchChange = false;
int g_DebugLevel = 0;

CBasePlayer@ ListenPlayer ()
{
	return  g_PlayerFuncs.FindPlayerByIndex( 1 );
}

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Cheeseh" );
	g_Module.ScriptInfo.SetContactInfo( "rcbot.bots-united.com" );
	
	g_BotManager.PluginInit();
	
	@m_pAddBot = @CConCommand( "addbot", "Adds a new bot", @AddBotCallback );

	@m_pRCBotWaypointConvertType = @CConCommand( "waypoint_convert_type", "Convert waypoint type to other", @WaypointConvertType );
//ConvertFlagsToOther WaypointConvertType
	@m_pRCBotWaypointOff = @CConCommand( "waypoint_off", "Display waypoints off", @WaypointOff );
	@m_pRCBotWaypointOn = @CConCommand( "waypoint_on", "Displays waypoints on", @WaypointOn );
	@m_pRCBotWaypointAdd = @CConCommand( "waypoint_add", "Adds a new waypoint", @WaypointAdd );
	@m_pRCBotWaypointDelete = @CConCommand( "waypoint_delete", "deletes a new waypoint", @WaypointDelete );
	@m_pRCBotWaypointLoad = @CConCommand( "waypoint_load", "Loads waypoints", @WaypointLoad );
	@m_pRCBotWaypointClear = @CConCommand( "waypoint_clear", "Clears waypoints", @WaypointClear );
	@m_pRCBotWaypointSave = @CConCommand( "waypoint_save", "Saves waypoints", @WaypointSave );
	@m_pPathWaypointCreate1 = @CConCommand( "pathwaypoint_create1", "Adds a new path from", @PathWaypoint_Create1 );
	@m_pPathWaypointCreate2 = @CConCommand( "pathwaypoint_create2", "Adds a new path to", @PathWaypoint_Create2 );
	@m_pExplo = @CConCommand ("explo","an explosion!!!",@Explo);
	@m_pPathWaypointRemove1 = @CConCommand( "pathwaypoint_remove1", "removes a new path from", @PathWaypoint_Remove1 );
	@m_pPathWaypointRemove2 = @CConCommand( "pathwaypoint_remove2", "removed a new path to", @PathWaypoint_Remove2 );
	@m_pPathWaypointRemovePathsFrom = @CConCommand( "pathwaypoint_remove_from", "removes paths from this waypoint", @PathWaypoint_RemovePathsFrom );
	@m_pPathWaypointRemovePathsTo = @CConCommand( "pathwaypoint_remove_to", "removedpaths to this waypoint", @PathWaypoint_RemovePathsTo );

	@m_pRCBotWaypointInfo = @CConCommand ( "waypoint_info", "print waypoint info",@WaypointInfo);
	@m_pRCBotWaypointGiveType = @CConCommand ( "waypoint_givetype", "give waypoint type(s)",@WaypointGiveType);
	@m_pRCBotWaypointRemoveType = @CConCommand ( "waypoint_removetype", "remove waypoint type(s)",@WaypointRemoveType);
	@m_pRCBotWaypointToggleType = @CConCommand ( "waypoint_toggletype", "toggle waypoint type(s)",@WaypointToggleType);
	@m_pDebugBot = @CConCommand ( "debug" , "debug messages toggle" , @DebugBot );
	@GodMode = @CConCommand("godmode","god mode",@GodModeFunc);
	@NoClipMode = @CConCommand("noclip","noclip",@NoClipModeFunc);
	@m_pNotouchMode = @CConCommand("notouch","no touch mode",@NoTouchFunc);
	@m_pNoTargetMode = @CConCommand("notarget","monsters dont shoot",@NoTargetMode);
  
	@m_pRCBotKillbots = @CConCommand( "killbots", "Kills all bots", @RCBot_Killbots );

	@m_pRCBotSearch = @CConCommand( "search", "test search func", @RCBotSearch );

	@m_pVisRevs = CCVar("visrevs", 100, "Reduce for better CPU performance, increase for better bot performance", ConCommandFlag::AdminOnly);
	@m_pNavRevs = CCVar("navrevs", 100, "Reduce for better CPU performance, increase for better bot performance", ConCommandFlag::AdminOnly);

}

void NoTargetMode ( const CCommand@ args )
{
	CBasePlayer@ player = ListenPlayer();

	if ( player.pev.flags & FL_NOTARGET == FL_NOTARGET )
	{
		player.pev.flags &= ~FL_NOTARGET;
		SayMessageAll(player,"No target mode disabled");
	}
	else
	{
		player.pev.flags |= FL_NOTARGET;
		SayMessageAll(player,"No target mode enabled");
	}
}

void Explo ( const CCommand@ args )
{
	CBaseEntity@ player = ListenPlayer();// g_ConCommandSystem.GetCurrentPlayer();
	TraceResult tr;
		// Ok set noise to forward vector
	g_EngineFuncs.MakeVectors(player.pev.v_angle);

	// CreateExplosion(const Vector& in vecCenter, const Vector& in vecAngles, edict_t@ pOwner, int iMagnitude, bool fDoDamage)
	g_Utility.TraceLine( player.EyePosition(), player.EyePosition() + g_Engine.v_forward * 2048.0f, dont_ignore_monsters,dont_ignore_glass, player.edict(), tr );

	g_EntityFuncs.CreateExplosion(tr.vecEndPos - g_Engine.v_forward*16,Vector(0,0,0),player.edict(),1024,true);
}

void NoTouchFunc ( const CCommand@ args )
{
	CBasePlayer@ player = ListenPlayer();

	g_NoTouchChange = true;

	// not doing anything yet
	g_NoTouch = !g_NoTouch;	

	if ( player !is null )
	{
		Observer@ o = player.GetObserver();	

		if ( o !is null )
		{
				if ( g_NoTouch == false )
				{
					o.StopObserver(true);
				}
				else
				{
					o.StartObserver(player.pev.origin, player.pev.angles, false);
				}
			
		}
	}

	if ( g_NoTouch )
		SayMessageAll(player,"No touch mode disabled");
	else 	
		SayMessageAll(player,"No touch mode enabled");			
}

void DebugBot ( const CCommand@ args )
{
	CBasePlayer@ player = ListenPlayer();

	g_DebugOn = !g_DebugOn;

	if ( g_DebugOn )
		SayMessageAll(player,"Debug on");
	else
		SayMessageAll(player,"Debug off");
}

void WaypointToggleType ( const CCommand@ args )
{
	array<string> types;

	CBasePlayer@ player = ListenPlayer();

	for ( int i = 1 ; i < args.ArgC(); i ++ )
	{
		types.insertLast(args.Arg(i));
	}

	int flags = g_WaypointTypes.parseTypes(types);

	if ( flags > 0 )
	{
		int wpt = g_Waypoints.getNearestWaypointIndex(player.pev.origin,player);

		if ( wpt != -1 )
		{
			CWaypoint@ pWpt =  g_Waypoints.getWaypointAtIndex(wpt);
			
			if ( pWpt.hasFlags(flags) )
				pWpt.m_iFlags &= ~flags;
			else
				pWpt.m_iFlags |= flags;
		}
	}
}
//ConvertFlagsToOther WaypointConvertType
void WaypointConvertType ( const CCommand@ args )
{
	array<string> convFrom;
	array<string> convTo;

	if ( args.ArgC() > 2 )
	{
		convFrom.insertLast(args.Arg(1));
		convTo.insertLast(args.Arg(2));	

		int iFlagsFrom = g_WaypointTypes.parseTypes(convFrom);
		int iFlagsTo = g_WaypointTypes.parseTypes(convTo);
	
		g_Waypoints.ConvertFlagsToOther(iFlagsFrom,iFlagsTo);
	}
}

void WaypointGiveType ( const CCommand@ args )
{
	array<string> types;

	CBasePlayer@ player = ListenPlayer();

	for ( int i = 1 ; i < args.ArgC(); i ++ )
	{
		types.insertLast(args.Arg(i));
	}

	int flags = g_WaypointTypes.parseTypes(types);

	if ( flags > 0 )
	{
		int wpt = g_Waypoints.getNearestWaypointIndex(player.pev.origin,player);

		if ( wpt != -1 )
		{
			CWaypoint@ pWpt =  g_Waypoints.getWaypointAtIndex(wpt);

			if ( flags & W_FL_UNREACHABLE == W_FL_UNREACHABLE )
			{
				g_Waypoints.PathWaypoint_RemovePathsFrom(wpt);
				g_Waypoints.PathWaypoint_RemovePathsTo(wpt);
			}

			pWpt.m_iFlags |= flags;
		}
	}	
}

void WaypointClear ( const CCommand@ args )
{
	g_Waypoints.ClearWaypoints();
}

void WaypointRemoveType ( const CCommand@ args )
{
	array<string> types;

	CBasePlayer@ player = ListenPlayer();

	for ( int i = 0 ; i < args.ArgC(); i ++ )
	{
		types.insertLast(args.Arg(i));
	}

	int flags = g_WaypointTypes.parseTypes(types);

	int wpt = g_Waypoints.getNearestWaypointIndex(player.pev.origin,player);

	if ( wpt != -1 )
	{
		CWaypoint@ pWpt =  g_Waypoints.getWaypointAtIndex(wpt);

		pWpt.m_iFlags &= ~flags;
	}
}

void GodModeFunc ( const CCommand@ args )
{
	CBasePlayer@ player = ListenPlayer();
	
	if ( player.pev.flags & FL_GODMODE == FL_GODMODE )
	{
		player.pev.flags &= ~FL_GODMODE;
		SayMessageAll(player,"God mode disabled");
	}
	else 
	{
		player.pev.flags |= FL_GODMODE;
		SayMessageAll(player,"God mode enabled");
	}
}

void NoClipModeFunc ( const CCommand@ args )
{
	CBasePlayer@ player = ListenPlayer();
	
	if ( player.pev.movetype != MOVETYPE_NOCLIP )
	{
		player.pev.movetype = MOVETYPE_NOCLIP;
		SayMessageAll(player,"No clip mode enabled");
	}
	else 
	{
		player.pev.movetype = MOVETYPE_WALK;
		SayMessageAll(player,"Noclip mode disabled");
	}
}

void RCBotSearch ( const CCommand@ args )
{
	Vector v = ListenPlayer().pev.origin;
	CBaseEntity@ pent = null;

	while ( (@pent =  g_EntityFuncs.FindEntityByClassname(pent, "*")) !is null )
	{
		if ( (UTIL_EntityOrigin(pent) - v).Length() < 200 )
		{
			if ( pent.GetClassname() == "func_door" )
			{
				CBaseDoor@ door = cast<CBaseDoor@>( pent );
				bool open = UTIL_DoorIsOpen(door,ListenPlayer());

				if ( open )
					BotMessage("func_door UNLOCKED");
				else 
					BotMessage("func_door LOCKED!!");
			}
			BotMessage(pent.GetClassname() + " frame="+pent.pev.frame + " distance = " + (UTIL_EntityOrigin(pent)-v).Length());			
		}
	}
}

void RCBot_Killbots( const CCommand@ args )
{
	for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
		
		if( pPlayer is null )
			continue;
			
		if( ( pPlayer.pev.flags & FL_FAKECLIENT ) == 0 )
			continue;
			
		pPlayer.Killed(pPlayer.pev, 0);
	}
}

// ------------------------------------
// COMMANDS - 	start
// ------------------------------------
void AddBotCallback( const CCommand@ args )
{
	BotManager::BaseBot@ pBot = g_BotManager.CreateBot( );

}

void WaypointInfo ( const CCommand@ args )
{
	g_Waypoints.WaypointInfo(ListenPlayer());
}

void WaypointLoad ( const CCommand@ args )
{
	g_Waypoints.Load();
}
void WaypointAdd ( const CCommand@ args )
{
	CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( 1 );
	array<string> types;
	for ( int i = 1 ; i < args.ArgC(); i ++ )
	{
		types.insertLast(args.Arg(i));
	}

	int flags = g_WaypointTypes.parseTypes(types);

	if ( player.pev.flags & FL_DUCKING == FL_DUCKING )
		flags = W_FL_CROUCH;

	g_Waypoints.addWaypoint(player.pev.origin,flags,player);
}

void WaypointOff ( const CCommand@ args )
{
	g_Waypoints.WaypointsOn(false);
}

void WaypointOn ( const CCommand@ args )
{
	g_Waypoints.WaypointsOn(true);
}

void WaypointDelete ( const CCommand@ args )
{
CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( 1 );

	int wpt = g_Waypoints.getNearestWaypointIndex(player.pev.origin,player,-1,100.0f,false);

	if ( wpt != -1 )
	{
		g_Waypoints.deleteWaypoint(wpt);
	}
	
}

void WaypointSave ( const CCommand@ args )
{
	g_Waypoints.Save();
}

void PathWaypoint_Create1 ( const CCommand@ args )
{
	CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( 1 );

	g_Waypoints.PathWaypoint_Create1(player);
}

void PathWaypoint_Create2 ( const CCommand@ args )
{
	CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( 1 );
	
	g_Waypoints.PathWaypoint_Create2(player);
}

void PathWaypoint_Remove1 ( const CCommand@ args )
{
	CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( 1 );

	g_Waypoints.PathWaypoint_Remove1(player);
}

void PathWaypoint_Remove2 ( const CCommand@ args )
{
	CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( 1 );
	
	g_Waypoints.PathWaypoint_Remove2(player);
}

void PathWaypoint_RemovePathsFrom  ( const CCommand@ args )
{
	CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( 1 );

	int wpt = g_Waypoints.getNearestWaypointIndex(player.pev.origin,player);

	if ( wpt != -1 )
	{
		g_Waypoints.PathWaypoint_RemovePathsFrom(wpt);
	}
}

void PathWaypoint_RemovePathsTo ( const CCommand@ args )
{
	CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( 1 );

	int wpt = g_Waypoints.getNearestWaypointIndex(player.pev.origin,player);

	if ( wpt != -1 )
	{
		g_Waypoints.PathWaypoint_RemovePathsTo(wpt);
	}
}
// ------------------------------------
// COMMANDS - 	end
// ------------------------------------
