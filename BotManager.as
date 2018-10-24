/*
*	Bot manager plugin
*	This is a sample script.
*/

#include "BotManagerInterface"
#include "BotWaypoint"
#include "CBotTasks"
#include "UtilFuncs"
#include "BotWeapons"

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

int g_DebugBot;
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
	//@m_pDebugBot = @ConCommand ( "debug_bot" , "debug a bot" , @DebugBot );
	@GodMode = @CConCommand("godmode","god mode",@GodModeFunc);
	@NoClipMode = @CConCommand("noclip","noclip",@NoClipModeFunc);
	@m_pRCBotKill = @CConCommand( "test", "test func", @RCBot_Kill );
	

}


void DebugBot ( const CCommand@ args )
{
	if ( args.ArgC() > 0 )		
	{
		g_DebugBot = atoi(args.Arg(0));
	}
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
	//int i = atoi(args.Arg(1));

	//RCBot@ bot = RCBot@(g_BotManager.FindBot(g_PlayerFuncs.FindPlayerByIndex(i)));

	CBasePlayer@ p = ListenPlayer();

        TraceResult tr;


		g_EngineFuncs.MakeVectors(p.pev.v_angle);
//void TraceHull(const Vector& in vecStart, const Vector& in vecEnd, IGNORE_MONSTERS igmon,HULL_NUMBER hullNumber, edict_t@ pEntIgnore, TraceResult& out ptr)

        g_Utility.TraceLine( p.pev.origin, p.pev.origin + g_Engine.v_forward*2000, ignore_monsters,dont_ignore_glass, null, tr );


	CBasePlayerWeapon@ w = findBestWeapon(p,tr.vecEndPos);

	if ( w !is null )
	{
		BotMessage("Best Weapon is : " + w.GetClassname());
	}
	else
		BotMessage("No Best Weapon! :(");
	//if ( w.GetClassname() )
	{

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

class CBits
{
	CBits ( int length )
	{
		bits = array<int>((length/32) + 1);
	}

	bool getBit ( int longbit )
	{
		int bit = 1<<(longbit % 32);
		int byte = longbit / 32;

		return (bits[byte] & bit) == bit;
	}

	void setBit ( int longbit , bool val )
	{
		int bit = 1<<(longbit % 32);
		int byte = longbit / 32;

		if ( val )
			bits[byte] |= bit;
		else
			bits[byte] &= ~bit;
	}

	void reset ()
	{
		for ( uint i = 0; i < bits.length(); i ++  )
		{
			bits[i] = 0;
		}
	}

	array<int> bits;
}

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

	CBaseEntity@ m_pEnemy;

	CBotVisibles@ m_pVisibles;

	CBasePlayerWeapon@ m_pCurrentWeapon;

	RCBot( CBasePlayer@ pPlayer )
	{
		super( pPlayer );

		init = false;

		@m_pVisibles = CBotVisibles(this);

		SpawnInit();		
	}

	bool IsEnemy ( CBaseEntity@ entity )
	{
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

			SpawnInit();

			return; // Dead , nothing else to do
		}

		init = false;

		if ( m_pEnemy !is null )
		{
			if ( !IsEnemy(m_pEnemy) )
				@m_pEnemy = null;
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
		if ( m_pEnemy !is null )
		{
			CBasePlayerWeapon@ desiredWeapon = null;

			@desiredWeapon = findBestWeapon(m_pPlayer,m_pEnemy.pev.origin,m_pEnemy);

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

			if ( m_pEnemy is null )
				@m_pEnemy = ent;
			else if ( getEnemyFactor(ent) < getEnemyFactor(m_pEnemy) )
				@m_pEnemy = ent;
		}
	}

	void lostVisible ( CBaseEntity@ ent )
	{
		if ( m_pEnemy is ent )
		{
			@m_pEnemy = null;
		}
	}

	void SpawnInit ()
	{
		if ( init == true )
			return;

		init = true;

		@m_pCurrentSchedule = null;
		@navigator = null;	
		@m_pEnemy = null;
		m_pVisibles.reset();
	}

	void DoVisibles ()
	{
		// update visible objects
		m_pVisibles.update();
	}

	void DoMove ()
	{
		if ( navigator !is null )
			navigator.execute(this);
	}

	void DoLook ()
	{
		if ( m_pEnemy !is null )
		{
			setLookAt(m_pEnemy.pev.origin);
			//BotMessage("LOOKING AT ENEMY!!!\n");
		}
	}

	void DoButtons ()
	{
		if ( m_pEnemy !is null )
		{
			// attack
			if( Math.RandomLong( 0, 100 ) < 90 )
				PressButton(IN_ATTACK);

			//BotMessage("SHOOTING ENEMY!!!\n");
		}
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
			CBotUtilities@ util = CBotUtilities(this);

			@m_pCurrentSchedule = util.execute(this);
		}
	}
}

BotManager::BaseBot@ CreateRCBot( CBasePlayer@ pPlayer )
{
	return @RCBot( pPlayer );
}