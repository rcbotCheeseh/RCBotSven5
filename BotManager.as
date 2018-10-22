/*
*	Bot manager plugin
*	This is a sample script.
*/

#include "BotManagerInterface"
#include "BotWaypoint"
#include "CBotTasks"
#include "UtilFuncs"
BotManager::BotManager g_BotManager( @CreateRCBot );

CConCommand@ m_pAddBot;
CConCommand@ m_pRCBotWaypointAdd;
CConCommand@ m_pRCBotWaypointDelete;
CConCommand@ m_pRCBotWaypointOff;
CConCommand@ m_pRCBotWaypointOn;
CConCommand@ m_pPathWaypointCreate1;
CConCommand@ m_pPathWaypointCreate2;
CConCommand@ m_pRCBotWaypointLoad;
CConCommand@ m_pRCBotWaypointSave;
CConCommand@ m_pRCBotKill;
CConCommand@ yawc;

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

	@m_pRCBotWaypointOff = @CConCommand( "waypoint_off", "Display waypoints off", @WaypointOff );
	@m_pRCBotWaypointOn = @CConCommand( "waypoint_on", "Displays waypoints on", @WaypointOn );
	@m_pRCBotWaypointAdd = @CConCommand( "waypoint_add", "Adds a new waypoint", @WaypointAdd );
	@m_pRCBotWaypointDelete = @CConCommand( "waypoint_delete", "Adds a new waypoint", @WaypointDelete );
	@m_pRCBotWaypointLoad = @CConCommand( "waypoint_load", "Loads waypoints", @WaypointLoad );
	@m_pRCBotWaypointSave = @CConCommand( "waypoint_save", "Saves waypoints", @WaypointSave );
	@m_pPathWaypointCreate1 = @CConCommand( "pathwaypoint_create1", "Adds a new path from", @PathWaypoint_Create1 );
	@m_pPathWaypointCreate2 = @CConCommand( "pathwaypoint_create2", "Adds a new path to", @PathWaypoint_Create2 );
	@m_pRCBotKill = @CConCommand( "kill", "kills a bot", @RCBot_Kill );
	@yawc = @CConCommand( "waypoint_yaw", "Display waypoints off", @WptYaw );

}

void RCBot_Kill ( const CCommand@ args )
{
	//int i = atoi(args.Arg(1));

	//RCBot@ bot = RCBot@(g_BotManager.FindBot(g_PlayerFuncs.FindPlayerByIndex(i)));


}

void WptYaw ( const CCommand@ args )
{
	int i = atoi(args.Arg(1));

	CWaypoint@ wpt = g_Waypoints.getWaypointAtIndex(i);

	CBasePlayer@ player = ListenPlayer();

	float yaw = UTIL_yawAngleFromEdict(wpt.m_vOrigin,player.pev.v_angle,player.pev.origin);

	BotMessage("Yaw = " + yaw + "\n");
}
// ------------------------------------
// COMMANDS - 	start
// ------------------------------------
void AddBotCallback( const CCommand@ args )
{
	/*if( args.ArgC() < 2 )
	{
		g_Game.AlertMessage( at_console, "Usage: addbot <name>" );
		return;
	}*/

	BotManager::BaseBot@ pBot = g_BotManager.CreateBot( );

}


void WaypointLoad ( const CCommand@ args )
{
	g_Waypoints.Load();
}
void WaypointAdd ( const CCommand@ args )
{
	CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( 1 );

	g_Waypoints.addWaypoint(player.pev.origin);
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
	//g_Waypoints.addWaypoint();
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
// ------------------------------------
// COMMANDS - 	end
// ------------------------------------

// ------------------------------------
// BOT BASE - START
// ------------------------------------
final class RCBot : BotManager::BaseBot
{	
	private float m_fNextThink = 0;

	RCBotNavigator@ navigator;

	RCBotSchedule@ m_pCurrentSchedule;

	RCBot( CBasePlayer@ pPlayer )
	{
		super( pPlayer );
	}

	Vector origin ()
	{
		return m_pPlayer.pev.origin;
	}

	void touchedWpt ( CWaypoint@ wpt )
	{
		if ( wpt.hasFlags(W_FL_JUMP) )
			PressButton(IN_JUMP);
	}

	WptColor@ col = WptColor(255,255,255);

	void followingWpt ( CWaypoint@ wpt )
	{
		if ( wpt.hasFlags(W_FL_CROUCH) )
			PressButton(IN_DUCK);

		setMove(wpt.m_vOrigin);

		drawBeam (ListenPlayer(), m_pPlayer.pev.origin, wpt.m_vOrigin, col, 1 );

	}

	void Think()
	{
		//if ( m_fNextThink > g_Engine.time )
		//	return;

		ReleaseButtons();

		// 100 ms think
		//m_fNextThink = g_Engine.time + 0.1;

		BotManager::BaseBot::Think();
		
		//If the bot is dead and can be respawned, send a button press
		if( Player.pev.deadflag >= DEAD_RESPAWNABLE )
		{
			if( Math.RandomLong( 0, 100 ) > 10 )
				PressButton(IN_ATTACK);

			@m_pCurrentSchedule = null;
			@navigator = null;

			return; // Dead , nothing else to do
		}

		
		/*
		KeyValueBuffer@ pInfoBuffer = g_EngineFuncs.GetInfoKeyBuffer( Player.edict() );
		
		pInfoBuffer.SetValue( "topcolor", Math.RandomLong( 0, 255 ) );
		pInfoBuffer.SetValue( "bottomcolor", Math.RandomLong( 0, 255 ) );
		
		if( Math.RandomLong( 0, 100 ) > 10 )
			Player.pev.button |= IN_ATTACK;
		else
			Player.pev.button &= ~IN_ATTACK;
			
		for( uint uiIndex = 0; uiIndex < 3; ++uiIndex )
		{
			m_vecVelocity[ uiIndex ] = Math.RandomLong( -50, 50 );
		}*/

		DoMove();
		DoLook();
		DoButtons();
		DoTasks();
	}

	void DoVisibles ()
	{
		// update visible objects
	}

	void DoMove ()
	{
		if ( navigator !is null )
			navigator.execute(this);
	}

	void DoLook ()
	{

	}

	void DoButtons ()
	{

	}

	void DoTasks ()
	{
		if ( m_pCurrentSchedule !is null )
		{
			if ( m_pCurrentSchedule.execute(this) )
			{
				@m_pCurrentSchedule = null;
			}			
		}
		else
		{
			@m_pCurrentSchedule = CFindPathSchedule(this);
		}
	}
}

BotManager::BaseBot@ CreateRCBot( CBasePlayer@ pPlayer )
{
	return @RCBot( pPlayer );
}