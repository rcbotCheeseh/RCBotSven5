/*
*	Bot manager plugin
*	This is a sample script.
*/

#include "BotManagerInterface"
#include "BotWaypoint"
#include "CBotTasks"
#include "UtilFuncs"
#include "BotWeapons"
#include "CBotBits"

BotManager::BotManager g_BotManager( @CreateRCBot );

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
CConCommand@ m_pNoTargetMode;
CConCommand@ m_pRCBotWaypointToggleType;
CConCommand@ m_pPathWaypointRemovePathsFrom;
CConCommand@ m_pPathWaypointRemovePathsTo;

bool g_DebugOn = false;
bool g_NoTouch = false;
bool g_NoTouchChange = false;
int g_DebugLevel = 0;

	const int PRIORITY_NONE = 0;
	const int PRIORITY_LADDER = 1;
	const int PRIORITY_TASK = 2;
	const int PRIORITY_HURT = 3;
	const int PRIORITY_ATTACK = 2;
	
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
	@m_pRCBotWaypointDelete = @CConCommand( "waypoint_delete", "deletes a new waypoint", @WaypointDelete );
	@m_pRCBotWaypointLoad = @CConCommand( "waypoint_load", "Loads waypoints", @WaypointLoad );
	@m_pRCBotWaypointClear = @CConCommand( "waypoint_clear", "Clears waypoints", @WaypointClear );
	@m_pRCBotWaypointSave = @CConCommand( "waypoint_save", "Saves waypoints", @WaypointSave );
	@m_pPathWaypointCreate1 = @CConCommand( "pathwaypoint_create1", "Adds a new path from", @PathWaypoint_Create1 );
	@m_pPathWaypointCreate2 = @CConCommand( "pathwaypoint_create2", "Adds a new path to", @PathWaypoint_Create2 );

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

	int flags = 0;

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



const int VIS_FL_NONE = 0;
const int VIS_FL_BODY = 1;
const int VIS_FL_HEAD = 2;

class CBotVisibles
{
	CBotVisibles ( RCBot@ bot )
	{
		@m_pCurrentEntity = null;
		@bits_body = CBits(g_Engine.maxEntities+1);
		@bits_head = CBits(g_Engine.maxEntities+1);
		@m_pBot = bot;
	}

	EHandle m_pNearestAvoid = null;
	float m_fNearestAvoidDist = 0;

	bool CanAvoid ( CBaseEntity@ ent )
	{
		if ( m_pBot.distanceFrom(ent) > 200 )
			return false;
		if ( ent == m_pBot.m_pPlayer )
			return false;
		if ( ent.pev.flags & FL_CLIENT == FL_CLIENT )
			return true;
		if ( ent.pev.flags & FL_MONSTER == FL_MONSTER )
			return true;

		return false;		
	}

	int getFlags ( bool bBodyVisible, bool bHeadVisible )
	{
		int ret = 0;

		if ( bBodyVisible )
			ret |= VIS_FL_BODY;
		
		if ( bHeadVisible )
			ret |= VIS_FL_HEAD;

		return ret;
	}

	int isVisible ( int iIndex )
	{
		return getFlags(bits_body.getBit(iIndex),bits_head.getBit(iIndex));
	}

	void setVisible ( CBaseEntity@ ent, bool bBodyVisible, bool bHeadVisible )
	{
		if ( ent is null )
		{
			// ARG?
			return;
		}
		
		int flags = getFlags(bBodyVisible,bHeadVisible);
		int iIndex = ent.entindex();
		bool wasVisible = isVisible(iIndex) > 0;

		//BotMessage("setVisible iIndex = " + iIndex + ", bVisible = " + bVisible + "\n");

		// not visible now
		if ( flags == 0 )
		{
			if ( m_pNearestAvoid == ent )
				m_pNearestAvoid = null;

			// was visible before
			if ( wasVisible ) // indicate state change
				m_pBot.lostVisible(ent);
		}
		else 
		{
			if ( !wasVisible )
				m_pBot.newVisible(ent);
		}

		bits_body.setBit(iIndex,bBodyVisible);
		bits_head.setBit(iIndex,bHeadVisible);
	}	

	void reset ()
	{
		bits_body.reset();
		bits_head.reset();
	}

	void update (  )
	{
		CBasePlayer@ player = m_pBot.m_pPlayer;
		int iLoops = 0;
		CBaseEntity@ pStart = m_pCurrentEntity;

		if ( m_pNearestAvoid.GetEntity() !is null )
		{
			if ( CanAvoid(m_pNearestAvoid) )
				m_fNearestAvoidDist = m_pBot.distanceFrom(m_pNearestAvoid);
			else
				m_pNearestAvoid = null;
		}

		do
		{
			CBaseEntity@ groundEntity = g_EntityFuncs.Instance(player.pev.groundentity);
			int flags = 0;
			bool bBodyVisible = false;
			bool bHeadVisible = false;
				
   			@m_pCurrentEntity = g_EntityFuncs.FindEntityByClassname(m_pCurrentEntity, "*"); 
			
			iLoops ++;
			
			if ( m_pCurrentEntity is null )
			{
				continue;
			}

			if ( m_pCurrentEntity is player )
				continue;

			if ( groundEntity !is m_pCurrentEntity )
			{
				
				if ( !player.FInViewCone(m_pCurrentEntity) )
				{
					setVisible(m_pCurrentEntity,false,false);
					continue;
				}			

				bBodyVisible = UTIL_IsVisible(player.EyePosition(),m_pCurrentEntity,player);

				if ( m_pCurrentEntity.pev.flags & FL_MONSTER == FL_MONSTER )
					bHeadVisible = UTIL_IsVisible(player.EyePosition(),m_pCurrentEntity.EyePosition());
			
				flags = getFlags(bBodyVisible,bHeadVisible);

				if ( flags == 0 )
				{
					setVisible(m_pCurrentEntity,false,false);
					continue;		
				}

				if ( CanAvoid(m_pCurrentEntity) )
				{
					if ( m_pNearestAvoid.GetEntity() is null || (m_pBot.distanceFrom(m_pCurrentEntity) < m_fNearestAvoidDist) )
					{
						m_pNearestAvoid =  m_pCurrentEntity;
					}
				}
			}

			setVisible(m_pCurrentEntity,bBodyVisible,bHeadVisible);

		}while ( iLoops < iMaxLoops );

		if ( isAvoiding() )
		{
			m_pBot.setAvoiding(true);;
			m_pBot.setAvoidVector(getAvoidVector());
		}
		else
			m_pBot.setAvoiding(false);

	}

	bool isAvoiding ()
	{
		return m_pNearestAvoid.GetEntity() !is null;
	}

	Vector getAvoidVector ()
	{
		return UTIL_EntityOrigin(m_pNearestAvoid.GetEntity());
	}

	CBaseEntity@ m_pCurrentEntity = null;
	//array<int> m_VisibleList;
	int iMaxLoops = 200;
	CBits@ bits_body;
	CBits@ bits_head;
	RCBot@ m_pBot;
	
};
// ------------------------------------
// BOT BASE - START
// ------------------------------------
final class RCBot : BotManager::BaseBot
{	
	private float m_fNextThink = 0;

	//RCBotNavigator@ navigator;

	RCBotSchedule@ m_pCurrentSchedule;

	float m_fNextShoutMedic;

	bool init;

	EHandle m_pEnemy;

	CBotVisibles@ m_pVisibles;

	CBotUtilities@ utils;

	CBotWeapons@ m_pWeapons;

	float m_flStuckTime = 0;

	Vector m_vLastSeeEnemy;
	bool m_bLastSeeEnemyValid = false;
	EHandle m_pLastEnemy = null;

	int m_iPrevHealthArmor;
	int m_iCurrentHealthArmor;

	RCBot( CBasePlayer@ pPlayer )
	{
		super( pPlayer );

		init = false;

		@m_pVisibles = CBotVisibles(this);

		@utils = CBotUtilities(this);

		@m_pWeapons = CBotWeapons();
		SpawnInit();				

		m_iPrevHealthArmor = 0;
		m_iCurrentHealthArmor = 0;

	}

    // anggara_nothing  
	void ClientCommand ( string command )
	{
		/*CBasePlayer@ pPlayer = m_pPlayer;

		NetworkMessage m(MSG_ONE, NetworkMessages::NetworkMessageType(9), pPlayer.edict());
			m.WriteString( command );
		m.End();*/


		//g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, command );		
	}

	float HealthPercent ()
	{
		return (float(m_pPlayer.pev.health))/m_pPlayer.pev.max_health;
	}

	float totalHealth ()
	{
		return (float(m_pPlayer.pev.health + m_pPlayer.pev.armorvalue))/(m_pPlayer.pev.max_health + m_pPlayer.pev.armortype);
	}

	bool BreakableIsEnemy ( CBaseEntity@ pBreakable )
	{
		
	// i. explosives required to blow breakable
	// ii. OR is not a world brush (non breakable) and can be broken by shooting
		if ( ((pBreakable.pev.flags & FL_WORLDBRUSH) != FL_WORLDBRUSH) && ((pBreakable.pev.spawnflags & 1)!=1) )
		{
			int iClass;
			
			if ( pBreakable.pev.effects & EF_NODRAW == EF_NODRAW )
				return false;

			iClass = pBreakable.Classify();

			switch ( iClass )
			{
				case -1:
				case 1:
				case 2:
				case 3:
				case 10:
				case 11:
				return false;
				default:
				break;
			}


			// forget it!!!
			if ( pBreakable.pev.health > 9999 )
				return false;

			if ( pBreakable.pev.target != "" )
				return true;
				
			if ( pBreakable.pev.targetname != "" )	
				return false;
			// w00tguy
			//if ( (iClass == -1) || (iClass == 1) || (iClass == 2) || (iClass == 3) || (iClass == 10) )
			//	return FALSE; // not an enemy

			Vector vSize = pBreakable.pev.size;
			Vector vMySize = m_pPlayer.pev.size;
			
			if ( (vSize.x >= vMySize.x) ||
				(vSize.y >= vMySize.y) ||
				(vSize.z >= (vMySize.z/2)) )
			{
				return true;
			}
		}

		return false;
	}	

	bool IsEnemy ( CBaseEntity@ entity )
	{

	//	return entity.pev.flags & FL_CLIENT == FL_CLIENT; (FOR TESTING)
		// can't attack this enemy
		if ( m_pWeapons.findBestWeapon(this,UTIL_EntityOrigin(entity),entity) is null ) 
			return false;

		

		if ( entity.GetClassname() == "func_breakable" )
			return BreakableIsEnemy(entity);

		if ( entity.pev.deadflag != DEAD_NO )
			return false;

		switch ( entity.Classify() )
		{
case 	CLASS_FORCE_NONE	:
case 	CLASS_PLAYER_ALLY	:
case 	CLASS_NONE	:
case 	CLASS_PLAYER	:
case 	CLASS_HUMAN_PASSIVE	:
case 	CLASS_ALIEN_PASSIVE	:
		return false;
case 	CLASS_MACHINE	:
case 	CLASS_HUMAN_MILITARY	:
case 	CLASS_ALIEN_MILITARY	:
case 	CLASS_ALIEN_MONSTER	:
case 	CLASS_ALIEN_PREY	:
case 	CLASS_ALIEN_PREDATOR	:
case 	CLASS_INSECT	:
case 	CLASS_PLAYER_BIOWEAPON	:
case 	CLASS_ALIEN_BIOWEAPON	:
case 	CLASS_XRACE_PITDRONE	:
case 	CLASS_XRACE_SHOCK	:
case 	CLASS_BARNACLE	:

		return !entity.IsPlayerAlly();

		default:
		break;
		}

		return false;
	}

	float distanceFrom ( Vector vOrigin )
	{
		return (vOrigin - m_pPlayer.pev.origin).Length();
	}

	float distanceFrom ( CBaseEntity@ pent )
	{
		return distanceFrom(UTIL_EntityOrigin(pent));
	}

	bool FVisible ( CBaseEntity@ pent )
	{
		return m_pVisibles.isVisible(pent.entindex()) > 0;
	}

	Vector origin ()
	{
		return m_pPlayer.pev.origin;
	}

	float m_flWaitTime = 0.0f;

	void touchedWpt ( CWaypoint@ wpt )                       
	{
		if ( wpt.hasFlags(W_FL_WAIT) )
			m_flWaitTime = g_Engine.time + 1.0f;

		if ( wpt.hasFlags(W_FL_JUMP) )
			PressButton(IN_JUMP);
		if ( wpt.hasFlags(W_FL_CROUCHJUMP) )
			{
				PressButton(IN_JUMP);
				PressButton(IN_DUCK);
			}

			if( wpt.hasFlags(W_FL_HUMAN_TOWER) )
			{
				if ( m_pCurrentSchedule !is null )
				{
					m_pCurrentSchedule.addTaskFront(CBotHumanTowerTask(wpt.m_vOrigin));
				}
			}
	}

	bool IsOnLadder ( ) 
	{ 
		return (m_pPlayer.pev.movetype == MOVETYPE_FLY);
	};			

	WptColor@ col = WptColor(255,255,255);

	void followingWpt ( CWaypoint@ wpt )
	{
		if ( wpt.hasFlags(W_FL_CROUCH) )
			PressButton(IN_DUCK);
		if ( IsOnLadder() )
			PressButton(IN_FORWARD);
		if ( wpt.hasFlags(W_FL_STAY_NEAR))
			setMoveSpeed(m_pPlayer.pev.maxspeed/4);
		//BotMessage("Following Wpt");	
		setMove(wpt.m_vOrigin);

		//drawBeam (ListenPlayer(), m_pPlayer.pev.origin, wpt.m_vOrigin, col, 1 );

	}

	float m_fNextTakeCover = 0;
	int m_iLastFailedWaypoint = -1;
	EHandle m_pHeal;

	bool isCurrentWeapon ( CBotWeapon@ weap )
	{
		return m_pWeapons.m_pCurrentWeapon is weap;
	}

	CBotWeapon@ getMedikit ()
	{
		return m_pWeapons.findBotWeapon("weapon_medikit");
	}

	void selectWeapon ( CBotWeapon@ weapon )
	{
		m_pWeapons.selectWeapon(this,weapon);
	}

	bool CanHeal ( CBaseEntity@ entity )
	{
        // select medikit
        CBotWeapon@ medikit = getMedikit();

        if ( medikit is null )
            return false;

        if ( medikit.getPrimaryAmmo(this) == 0 )
        {
            return false;
        }

		return ( entity.pev.flags & FL_CLIENT == FL_CLIENT ) && (entity.pev.health < entity.pev.max_health);
	}

	float getHealFactor ( CBaseEntity@ player )
	{
		return distanceFrom(player) * (1.0 - (float(player.pev.health) / player.pev.max_health));
	}

	void Think()
	{
		//if ( m_fNextThink > g_Engine.time )
		//	return;


		m_iCurrentPriority = PRIORITY_NONE;
		m_pWeapons.updateWeapons(this);

		ReleaseButtons();

		m_fDesiredMoveSpeed = m_pPlayer.pev.maxspeed;

		// 100 ms think
		//m_fNextThink = g_Engine.time + 0.1;

		BotManager::BaseBot::Think();
		
		//If the bot is dead and can be respawned, send a button press
		if( Player.pev.deadflag >= DEAD_RESPAWNABLE )
		{
			if( Math.RandomLong( 0, 100 ) > 10 )
				PressButton(IN_ATTACK);

			SpawnInit();

			return; // Dead , nothing else to do
		}


		m_iCurrentHealthArmor = int(m_pPlayer.pev.health + m_pPlayer.pev.armorvalue);

		if ( m_iCurrentHealthArmor < m_iPrevHealthArmor )
		{
			//int iDamage = m_iPrevHealthArmor - m_iCurrentHealthArmor;

			
				if ( m_pEnemy.GetEntity() !is null )
				{
					if ( m_fNextTakeCover < g_Engine.time )
					{
						@m_pCurrentSchedule = CBotTaskFindCoverSchedule(this,m_pEnemy.GetEntity());
						m_fNextTakeCover = g_Engine.time + 8.0;
					}				
				}
				else
				{
					// no enemy ,, who shot me?

					//w00tguy
					if ( m_pPlayer.pev.dmg_inflictor !is null )
					{
						CBaseEntity@ attacker = g_EntityFuncs.Instance(m_pPlayer.pev.dmg_inflictor);

						if ( attacker !is null )
						{
							m_iCurrentPriority = PRIORITY_HURT;
							setLookAt(UTIL_EntityOrigin(attacker));
							m_iCurrentPriority = PRIORITY_NONE;
						}

					}
				}
			
		}		

		m_iPrevHealthArmor = m_iCurrentHealthArmor;

		init = false;

		if ( m_pEnemy.GetEntity()  !is null )
		{
			if ( !IsEnemy(m_pEnemy.GetEntity() ) )
				m_pEnemy = null;
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
		DoTasks();
		DoVisibles();
		DoMove();
		DoLook();
		DoWeapons();
		DoButtons();

		
		
	}

	void DoWeapons ()
	{	
		m_pWeapons.DoWeapons(this,m_pEnemy);
	}

	float getEnemyFactor ( CBaseEntity@ entity )
	{
		return distanceFrom(entity.pev.origin) * entity.pev.size.Length();
	}

	void newVisible ( CBaseEntity@ ent )
	{
		if ( ent is null )
		{
			// WTFFFFF!!!!!!!
			return;
		}

		if ( CanHeal(ent) )
		{
			if ( m_pHeal.GetEntity() is null )
				m_pHeal = ent;
			else if ( getHealFactor(ent) < getHealFactor(m_pHeal) )
				m_pHeal = ent;
		}

		//BotMessage("New Visible " + ent.pev.classname + "\n");
		if ( IsEnemy(ent) )
		{
			BotMessage("NEW ENEMY !!!  " + ent.pev.classname + "\n");

			if ( m_pEnemy.GetEntity() is null )
				m_pEnemy = ent;
			else if ( getEnemyFactor(ent) < getEnemyFactor(m_pEnemy) )
				m_pEnemy = ent;
		}
	}

	void lostVisible ( CBaseEntity@ ent )
	{
		if ( m_pEnemy.GetEntity() is ent )
		{
			m_pLastEnemy = m_pEnemy.GetEntity();
			m_vLastSeeEnemy = m_pEnemy.GetEntity().pev.origin;
			m_bLastSeeEnemyValid = true;
			m_pEnemy = null;
		}

		if ( m_pHeal.GetEntity() is ent )
		{
			m_pHeal = null;
		}
	}

	void SpawnInit ()
	{
		if ( init == true )
			return;

		m_fNextShoutMedic = 0.0f;

		m_pWeapons.spawnInit();
		m_iLastFailedWaypoint = -1;
		init = true;

		@m_pCurrentSchedule = null;
	//	@navigator = null;	
		m_pEnemy = null;

	 m_bLastSeeEnemyValid = false;
		m_pLastEnemy = null;		
		m_pVisibles.reset();
		utils.reset();

		m_flStuckTime = 0;
		m_pHeal = null;
	}

	void DoVisibles ()
	{
		// update visible objects
		m_pVisibles.update();
	}

	void RemoveLastEnemy ()
	{
		m_pLastEnemy = null;
		m_bLastSeeEnemyValid = false;

	}
	bool HasWeapon ( string classname )
	{
		return m_pPlayer.HasNamedPlayerItem(classname) !is null;
	}

	void StopMoving ()
	{
		m_bMoveToValid = false;
	}

	void DoMove ()
	{
		//if ( navigator !is null )
		//	navigator.execute(this);

		if ( m_flWaitTime > g_Engine.time )
			setMoveSpeed(0.0f);

		if ( m_pPlayer.pev.flags & FL_FLY == FL_FLY )
			PressButton(IN_DUCK);
		
		if (  !m_bMoveToValid || (m_pPlayer.pev.velocity.Length() > (0.25*m_fDesiredMoveSpeed)) )
		{
			m_flStuckTime = g_Engine.time;
		}
		// stuck for more than 3 sec
		else if ( (m_flStuckTime > 0) && (g_Engine.time - m_flStuckTime) > 3.0 )
		{
			PressButton(IN_JUMP);
			m_flStuckTime = 0;
			// reset last enemy could cause lok issues
			m_pLastEnemy = null;
			m_bLastSeeEnemyValid = false;
		}		
	}

	void DoLook ()
	{
		CBaseEntity@ pEnemy = m_pEnemy.GetEntity();

		if ( pEnemy !is null )
		{						
			m_iCurrentPriority = PRIORITY_ATTACK;

			if ( m_pVisibles.isVisible(pEnemy.entindex()) & VIS_FL_HEAD == VIS_FL_HEAD )
				setLookAt(pEnemy.EyePosition());
			else
				setLookAt(UTIL_EntityOrigin(pEnemy));

			m_iCurrentPriority = PRIORITY_NONE;

			//BotMessage("LOOKING AT ENEMY!!!\n");
		}
		else if ( IsOnLadder() )		
		{
			m_iCurrentPriority = PRIORITY_LADDER;
			setLookAt(m_vMoveTo);
			m_iCurrentPriority = PRIORITY_NONE;
		}
		else if ( m_bLastSeeEnemyValid )
		{
			setLookAt(m_vLastSeeEnemy);
		}
		else if (m_bMoveToValid )
		{
			setLookAt(m_vMoveTo);
		}
	}

	void DoButtons ()
	{
		CBotWeapon@ pCurrentWeapon = m_pWeapons.getCurrentWeapon();

		if ( m_pEnemy.GetEntity() !is null )
			BotMessage("ENEMY");

		if ( (m_fNextShoutMedic < g_Engine.time) && (HealthPercent() < 0.5f) )
		{
			ClientCommand("medic");
			m_fNextShoutMedic = g_Engine.time + 30.0f;
		}
		if ( pCurrentWeapon !is null && pCurrentWeapon.needToReload() )
		{
			// attack
			if( Math.RandomLong( 0, 100 ) < 99 )
				PressButton(IN_RELOAD);

		}
		else if ( m_pEnemy.GetEntity() !is null )
		{
			bool bPressAttack1 = Math.RandomLong(0,100) < 95;
			bool bPressAttack2 = Math.RandomLong(0,100) < 25 && pCurrentWeapon !is null && pCurrentWeapon.CanUseSecondary();

			CBaseEntity@ groundEntity = g_EntityFuncs.Instance(m_pPlayer.pev.groundentity);		

			if ( pCurrentWeapon !is null )
			{
				if ( /*pCurrentWeapon.IsMelee() && */ groundEntity is m_pEnemy.GetEntity() )
					PressButton(IN_DUCK);

				if ( pCurrentWeapon.IsSniperRifle() && !pCurrentWeapon.IsZoomed() )
					bPressAttack2 = true;
			}
			
			if ( bPressAttack1 )
				PressButton(IN_ATTACK);
			if ( bPressAttack2 )
				PressButton(IN_ATTACK2);

			//BotMessage("SHOOTING ENEMY!!!\n");
		}

		
	}

	void DoTasks ()
	{
		m_iCurrentPriority = PRIORITY_TASK;

		if ( m_pCurrentSchedule !is null )
		{
			if ( m_pCurrentSchedule.execute(this) )
			{
				@m_pCurrentSchedule = null;
			}			
		}
		else
		{
			@m_pCurrentSchedule = utils.execute(this);
		}

		m_iCurrentPriority = PRIORITY_NONE;
	}
}

BotManager::BaseBot@ CreateRCBot( CBasePlayer@ pPlayer )
{
	return @RCBot( pPlayer );
}
