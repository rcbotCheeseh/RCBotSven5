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
CConCommand@ m_pRCBotWaypointLoad;
CConCommand@ m_pRCBotWaypointSave;
CConCommand@ m_pRCBotKill;
CConCommand@ GodMode;
CConCommand@ NoClipMode;
CConCommand@ m_pRCBotWaypointRemoveType;
CConCommand@ m_pRCBotWaypointGiveType;
CConCommand@ m_pDebugBot;
CConCommand@ m_pRCBotKillbots;

bool g_DebugOn;
int g_DebugLevel = 0;

	const int PRIORITY_NONE = 0;
	const int PRIORITY_TASK = 1;
	
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
	@m_pRCBotWaypointInfo = @CConCommand ( "waypoint_info", "print waypoint info",@WaypointInfo);
	@m_pRCBotWaypointGiveType = @CConCommand ( "waypoint_givetype", "give waypoint type",@WaypointGiveType);
	@m_pRCBotWaypointRemoveType = @CConCommand ( "waypoint_removetype", "remove waypoint type",@WaypointRemoveType);
	@m_pDebugBot = @CConCommand ( "debug" , "debug messages toggle" , @DebugBot );
	@GodMode = @CConCommand("godmode","god mode",@GodModeFunc);
	@NoClipMode = @CConCommand("noclip","noclip",@NoClipModeFunc);
	@m_pRCBotKill = @CConCommand( "test", "test func", @RCBot_Kill );
	@m_pRCBotKillbots = @CConCommand( "killbots", "Kills all bots", @RCBot_Killbots );

}


void DebugBot ( const CCommand@ args )
{
	g_DebugOn = !g_DebugOn;
}

void WaypointGiveType ( const CCommand@ args )
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

		pWpt.m_iFlags |= flags;
	}
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

void RCBot_Kill ( const CCommand@ args )
{
	Vector v = ListenPlayer().pev.origin;
CBaseEntity@ pent = null;

//FindEntityInSphere(CBaseEntity@ pStartEntity, const Vector& in vecCenter, float flRadius,const string& in szValue = "", const string& in szKeyword = "targetname")

        //while ( (@pent = g_EntityFuncs.FindEntityInSphere(pent, v, 512,"*", "classname"  )) !is null )

		 while ( (@pent = g_EntityFuncs.FindEntityByClassname(pent, "func_healthcharger"  )) !is null )
        {
				BotMessage(pent.GetClassname());			
        }
/*
	CBasePlayer@ p = ListenPlayer();

	BotMessage("MAX_ITEM_TYPES = " + MAX_ITEM_TYPES);

	for ( uint i = 0; i < MAX_ITEM_TYPES; i ++ )
	{
		CBasePlayerItem@ item = p.m_rgpPlayerItems(i);
		
		if ( item !is null )
		{
			CBasePlayerWeapon@ weapon = item.GetWeaponPtr();

			if ( weapon !is null )
			{
				// this is a weapon
				BotMessage("Weapon : " + item.GetClassname());

				BotMessage(" Primary Ammo: " + p.m_rgAmmo(weapon.PrimaryAmmoIndex()));
				if ( weapon.SecondaryAmmoIndex() >= 0)
				BotMessage(" Secondary Ammo: " + p.m_rgAmmo(weapon.SecondaryAmmoIndex()));
			}
			else
				BotMessage("Item : " + item.GetClassname());
		}
	}*/
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
	/*if( args.ArgC() < 2 )
	{
		g_Game.AlertMessage( at_console, "Usage: addbot <name>" );
		return;
	}*/

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



class CBotVisibles
{
	CBotVisibles ( RCBot@ bot )
	{
		@m_pCurrentEntity = null;
		@bits = CBits(g_Engine.maxEntities+1);
		@m_pBot = bot;
	}

	bool isVisible ( int iIndex )
	{
		return bits.getBit(iIndex);
	}

	void setVisible ( CBaseEntity@ ent, bool bVisible)
	{
		if ( ent is null )
		{
			// ARG?
			return;
		}
		int iIndex = ent.entindex();
		bool wasVisible = isVisible(iIndex);

		//BotMessage("setVisible iIndex = " + iIndex + ", bVisible = " + bVisible + "\n");

		if ( !bVisible )
		{
			if ( wasVisible )
				m_pBot.lostVisible(ent);
		}
		else 
		{
			if ( !wasVisible )
				m_pBot.newVisible(ent);
		}

		bits.setBit(iIndex,bVisible);
	}	

	void reset ()
	{
		bits.reset();
	}

	void update (  )
	{
		CBasePlayer@ player = m_pBot.m_pPlayer;
		int iLoops = 0;
		CBaseEntity@ pStart = m_pCurrentEntity;

		do
		{
   			@m_pCurrentEntity = g_EntityFuncs.FindEntityByClassname(m_pCurrentEntity, "*"); 

			iLoops ++;
			
			if ( m_pCurrentEntity is null )
			{
				continue;
			}

			if ( !player.FInViewCone(m_pCurrentEntity) )
			{
				setVisible(m_pCurrentEntity,false);
				continue;
			}			
		
			if ( !player.FVisible(m_pCurrentEntity,false) )
			{
				setVisible(m_pCurrentEntity,false);
				continue;		
			}

			setVisible(m_pCurrentEntity,true);
		}while ( iLoops < iMaxLoops );

	}

	CBaseEntity@ m_pCurrentEntity = null;
	//array<int> m_VisibleList;
	int iMaxLoops = 200;
	CBits@ bits;
	RCBot@ m_pBot;
	
};
// ------------------------------------
// BOT BASE - START
// ------------------------------------
final class RCBot : BotManager::BaseBot
{	
	private float m_fNextThink = 0;

	RCBotNavigator@ navigator;

	RCBotSchedule@ m_pCurrentSchedule;

	bool init;

	EHandle m_pEnemy;

	CBotVisibles@ m_pVisibles;

	CBasePlayerWeapon@ m_pCurrentWeapon;

	CBotUtilities@ utils;

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
		SpawnInit();				

		m_iPrevHealthArmor = 0;
		m_iCurrentHealthArmor = 0;
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
		return m_pVisibles.isVisible(pent.entindex());
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

		//BotMessage("Following Wpt");	
		setMove(wpt.m_vOrigin);

		//drawBeam (ListenPlayer(), m_pPlayer.pev.origin, wpt.m_vOrigin, col, 1 );

	}

	float m_fNextTakeCover = 0;
	int m_iLastFailedWaypoint = -1;

	void Think()
	{
		//if ( m_fNextThink > g_Engine.time )
		//	return;


		m_iCurrentPriority = PRIORITY_NONE;

		ReleaseButtons();

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
			int iDamage = m_iPrevHealthArmor - m_iCurrentHealthArmor;

			if ( iDamage > 1 )	
			{
				if ( m_pEnemy.GetEntity() !is null )
				{
					if ( m_fNextTakeCover < g_Engine.time )
					{
						@m_pCurrentSchedule = CBotTaskFindCoverSchedule(this,m_pEnemy.GetEntity());
						m_fNextTakeCover = g_Engine.time + 8.0;
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

		DoVisibles();
		DoMove();
		DoLook();
		DoWeapons();
		DoButtons();
		DoTasks();
	}

	void DoWeapons ()
	{	
		if ( m_pEnemy.GetEntity()  !is null )
		{
			CBasePlayerWeapon@ desiredWeapon = null;

			@desiredWeapon = findBestWeapon(m_pPlayer,m_pEnemy.GetEntity().pev.origin,m_pEnemy.GetEntity() );

			if ( desiredWeapon !is null )
			{
				if ( desiredWeapon !is m_pCurrentWeapon )
				{
					@m_pCurrentWeapon = desiredWeapon;
					m_pPlayer.SelectItem(m_pCurrentWeapon.GetClassname());
					BotMessage("SELECT " + m_pCurrentWeapon.GetClassname());
				}
			}
		}
	}

	float getEnemyFactor ( CBaseEntity@ entity )
	{
		return distanceFrom(entity.pev.origin);
	}

	void newVisible ( CBaseEntity@ ent )
	{
		if ( ent is null )
		{
			// WTFFFFF!!!!!!!
			return;
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
	}

	void SpawnInit ()
	{
		if ( init == true )
			return;
m_iLastFailedWaypoint = -1;
		init = true;

		@m_pCurrentSchedule = null;
		@navigator = null;	
		m_pEnemy = null;

	 m_bLastSeeEnemyValid = false;
		m_pLastEnemy = null;		
		m_pVisibles.reset();
		utils.reset();

		m_flStuckTime = 0;
	}

	void DoVisibles ()
	{
		// update visible objects
		m_pVisibles.update();
	}

	void StopMoving ()
	{
		m_bMoveToValid = false;
	}

	void DoMove ()
	{
		if ( navigator !is null )
			navigator.execute(this);

		
		if (  !m_bMoveToValid || (m_pPlayer.pev.velocity.Length() > (0.25*m_pPlayer.pev.maxspeed)) )
		{
			m_flStuckTime = g_Engine.time;
		}
		// stuck for more than 3 sec
		else if ( (m_flStuckTime > 0) && (g_Engine.time - m_flStuckTime) > 3.0 )
		{
			PressButton(IN_JUMP);
			m_flStuckTime = 0;
		}
	}

	void DoLook ()
	{
		if ( m_pEnemy.GetEntity() !is null )
		{
			CBaseEntity@ pEnemy = m_pEnemy.GetEntity();

			setLookAt(pEnemy.pev.origin + pEnemy.pev.view_ofs/2);
			//BotMessage("LOOKING AT ENEMY!!!\n");
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
		if ( m_pEnemy.GetEntity() !is null )
		{
			// attack
			if( Math.RandomLong( 0, 100 ) < 99 )
				PressButton(IN_ATTACK);

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