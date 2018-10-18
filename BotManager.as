/*
*	Bot manager plugin
*	This is a sample script.
*/

#include "BotManagerInterface"
#include "BotWaypoint"

BotManager::BotManager g_BotManager( @CreateRCBot );

CConCommand@ m_pAddBot;
CConCommand@ m_pRCBotWaypointAdd;
CConCommand@ m_pRCBotWaypointDelete;
CConCommand@ m_pRCBotWaypointOff;
CConCommand@ m_pRCBotWaypointOn;
CConCommand@ m_pPathWaypointCreate1;
CConCommand@ m_pPathWaypointCreate2;

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

	@m_pPathWaypointCreate1 = @CConCommand( "pathwaypoint_create1", "Adds a new path from", @PathWaypoint_Create1 );
	@m_pPathWaypointCreate2 = @CConCommand( "pathwaypoint_create2", "Adds a new path to", @PathWaypoint_Create2 );

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
// TASKS / SCHEDULES - 	START
// ------------------------------------
final class RCBotTask
{
	bool m_bComplete = false;
	bool m_bFailed = false;

	void Complete ()
	{
		m_bComplete = true;	
	}

	void Failed ()
	{
		m_bFailed = true;
	}	
}

final class RCBotSchedule
{
	bool m_bComplete = false;
	bool m_bFailed = false;

	array<RCBotTask@> m_pTasks;

	void addTaskFront ( RCBotTask@ pTask )
	{
		m_pTasks.insertAt(0,pTask);
	}

	void addTask ( RCBotTask@ pTask )
	{	
		m_pTasks.insertLast(pTask);
	}

	void DoTasks ()
	{

	}
}

// ------------------------------------
// TASKS / SCHEDULES - 	END
// ------------------------------------

// ------------------------------------
// BOT BASE - START
// ------------------------------------
final class RCBot : BotManager::BaseBot
{	
	private float m_fNextThink = 0;

	RCBot( CBasePlayer@ pPlayer )
	{
		super( pPlayer );
	}
	
	void Think()
	{
		if ( m_fNextThink > g_Engine.time )
			return;

		// 100 ms think
		m_fNextThink = g_Engine.time + 0.1;

		BotManager::BaseBot::Think();
		
		//If the bot is dead and can be respawned, send a button press
		if( Player.pev.deadflag >= DEAD_RESPAWNABLE )
		{
			if( Math.RandomLong( 0, 100 ) > 10 )
				Player.pev.button |= IN_ATTACK;
			else
				Player.pev.button &= ~IN_ATTACK;
		}
		else
			Player.pev.button &= ~IN_ATTACK;
		
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
		
	}

	void DoLook ()
	{

	}

	void DoButtons ()
	{

	}

	void DoTasks ()
	{

	}
}

BotManager::BaseBot@ CreateRCBot( CBasePlayer@ pPlayer )
{
	return @RCBot( pPlayer );
}