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
#include "BotVisibles"
#include "BotCommands"

BotManager::BotManager g_BotManager( @CreateRCBot );

const int PRIORITY_NONE = 0;
const int PRIORITY_WAYPOINT = 1;	
const int PRIORITY_LISTEN = 2;
const int PRIORITY_LAST_SEE_ENEMY = 3;
const int PRIORITY_TASK = 4;
const int PRIORITY_HURT = 5;
const int PRIORITY_STUCK = 5;
const int PRIORITY_ATTACK = 6;
const int PRIORITY_LADDER = 7;
const int PRIORITY_OVERRIDE = 8;

// ------------------------------------
// BOT BASE - START
// ------------------------------------
final class RCBot : BotManager::BaseBot
{	
	//private float m_fNextThink = 0;

	RCBotSchedule@ m_pCurrentSchedule;

	float m_fNextShoutMedic;
	float m_fNextShoutTakeCover;
	float m_fNextShout;

	bool init;

	EHandle m_pEnemy;

//	EHandle m_pNextEnemy;

	BotEnemiesVisible m_pEnemiesVisible;

	CBaseEntity@ m_pNearestTrain = null; // experimental - i.e. not yet implemented!

	CBotVisibles@ m_pVisibles;

	CBotUtilities@ utils;

	CBotWeapons@ m_pWeapons;

	EHandle m_pNearestTank;

	EHandle m_pNearestClient;

	float m_flStuckTime = 0;

	Vector m_vLastSeeEnemy;
	bool m_bLastSeeEnemyValid = false;
	EHandle m_pLastEnemy = null;
	float m_fLastSeeEnemyTime = 0;

	int m_iPrevHealthArmor;
	int m_iCurrentHealthArmor;

	float m_flJumpTime = 0.0f;

	int m_iLastWaypointFrom = 0;
	int m_iLastWaypointTo = 0;	
	bool m_bLastPathFailed = false;


	Vector m_vObjectiveOrigin;
	bool m_bObjectiveOriginValid;

	Vector m_vNoiseOrigin;
	EHandle m_pListenPlayer;
	Vector m_vListenOrigin;
	float m_flHearNoiseTime = 0;

	float m_fNextTakeCover = 0;
	int m_iLastFailedWaypoint = -1;
	EHandle m_pHeal;
	EHandle m_pRevive;
	
	EHandle m_pLastSeenBarney;
	EHandle m_pLastSeenScientist;

	EHandle m_pFollowingNPC;

	float m_flJumpPlatformTime = 0;
	CBaseEntity@ m_pExpectedPlatform = null;

	Vector m_vLadderVector;

	void setFollowingNPC ( CBaseEntity@ NPC )
	{
		m_pFollowingNPC = NPC;
	}

	CBaseEntity@ getNearestScientist ()
	{
		return m_pLastSeenScientist;
	}

	CBaseEntity@ getNearestBarney ()
	{
		return m_pLastSeenBarney;
	}

	bool IsScientistNearby ( )
	{
		return m_pLastSeenScientist.GetEntity() !is null;
	}

	bool IsBarneyNearby ( )
	{
		return m_pLastSeenBarney.GetEntity() !is null;
	}	

	bool IsBarneyFollowing ( )
	{
		if ( IsNPCFollowing () )
		{
			CBaseEntity@ NPC = m_pFollowingNPC.GetEntity();

			return NPC.GetClassname() == "monster_barney";
		}

		return false;		
	}

	bool IsScientistFollowing ()
	{
		if ( IsNPCFollowing () )
		{
			CBaseEntity@ NPC = m_pFollowingNPC.GetEntity();

			return NPC.GetClassname() == "monster_scientist";
		}

		return false;
	}

	bool IsNPCFollowing ()
	{
		if ( m_pFollowingNPC.GetEntity() !is null )
		{
			CBaseEntity@ NPC = m_pFollowingNPC.GetEntity();

			if ( NPC.pev.deadflag == DEAD_NO )
			{
        		CBaseMonster@ NPCm = cast<CBaseMonster@>(NPC);

				//if ( NPCm.CanPlayerFollow() )
				{					
					if ( NPCm.IsPlayerFollowing() )
					{
						return true;
					}
				}
			}
		}

		// reset
		m_pFollowingNPC = null;

		return false;
	}
	
	void setNearestTank ( CBaseEntity@ pTank )
	{
		//BotMessage("setNearestTank");

		if ( m_pNearestTank.GetEntity() is null )
			m_pNearestTank = pTank;
		else if ( m_pNearestTank.GetEntity() != pTank )
		{
			if ( distanceFrom(pTank) < distanceFrom(m_pNearestTank.GetEntity()) )
				m_pNearestTank = pTank;
		}
		
	}

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

	 	m_bLastSeeEnemyValid = false;
		m_pLastEnemy = null;
	}

	Vector getObjectiveOrigin ()
	{
		return m_vObjectiveOrigin;
	}

	bool isObjectiveOriginValid ()
	{
		return m_bObjectiveOriginValid;
	}

	void setObjectiveOrigin ( Vector vOrigin )
	{
		m_vObjectiveOrigin = vOrigin;
		m_bObjectiveOriginValid = true;
	}

	void ClientSay ( CBaseEntity@ talker, array<string> args )
	{		
		if ( args.length() > 1 )
		{
			bool OK = false;
			bool bBotHeard = false;
			
			Vector vTalker = talker.pev.origin;
		
			if ( args[1] == "come")
			{
				RCBotSchedule@ sched = SCHED_CREATE_NEW();
				RCBotTask@ task = SCHED_CREATE_PATH(vTalker,talker);

				bBotHeard = true;

				if ( task !is null )
				{
					sched.addTask(task);
					sched.addTask(CBotMoveToOrigin(vTalker));
					OK = true;
				}
			}
			else if ( args[1] == "wait")
			{
				RCBotSchedule@ sched = SCHED_CREATE_NEW();
				RCBotTask@ task = SCHED_CREATE_PATH(vTalker,talker);
				
				float fTime = 90.0f;

				bBotHeard = true;

				// should work for eg....
				//  "Wait 2 min" or "wait here 2 min" or "wait here for 2 mins"
				if ( args.length() > 2 )
				{
					uint arg = 2;

					// search for a number
					while ( arg < args.length() )
					{
						fTime = atof(args[arg++]);

						if ( fTime > 0.0f ) // valid number
							break;
					}

					if ( arg < args.length() )
					{
						if ( args[arg] == "min" || args[arg] == "mins" )
						{
							fTime *= 60.0f;
						}
						else if ( args[arg] == "hour" || args[arg] == "hours" )
						{
							fTime *= 3600.0f;
						}											
					}
				}

				// no time given
				if ( fTime == 0.0f )
					fTime = 90.0f;

				if ( task !is null )
				{
					sched.addTask(task);
					sched.addTask(CBotMoveToOrigin(vTalker));
					sched.addTask(CBotTaskWait(fTime,vTalker));
					OK = true;
				}
			}
			else if ( args[1] == "use" )
			{
				RCBotSchedule@ sched = SCHED_CREATE_NEW();
				
				CBaseEntity@ pTank = UTIL_FindNearestEntity ( "func_tank", talker.EyePosition(), 200.0f, false, false );

				bBotHeard = true;

				if ( pTank !is null )
				{
					if ( UTIL_CanUseTank(m_pPlayer,pTank) )
					{
						RCBotTask@ task = SCHED_CREATE_PATH(vTalker);

						if ( task !is null )
						{
							sched.addTask(task);
							sched.addTask(CBotMoveToOrigin(vTalker));
							sched.addTask(CBotTaskUseTank(pTank));
							
							OK = true;
						}
					}
				}
			}
			else if ( args[1] == "press") 
			{
				RCBotSchedule@ sched = SCHED_CREATE_NEW();
				
				CBaseEntity@ pButton = UTIL_FindNearestEntity ( "func_button", talker.EyePosition(), 128.0f, true, false );

				if ( pButton is null )
					@pButton = UTIL_FindNearestEntity ( "momentary_rot_button", talker.EyePosition(), 128.0f, true, false );

				bBotHeard = true;

				if ( pButton !is null )
				{
					RCBotTask@ task = SCHED_CREATE_PATH(vTalker);

					if ( task !is null )
					{
						sched.addTask(task);
						sched.addTask(CBotMoveToOrigin(vTalker));
						sched.addTask(CUseButtonTask(pButton));
						
						OK = true;
					}
				}
			}
			else if ( args[1] == "follow" )
			{
				bBotHeard = true;

				if ( args.length() > 2 )
				{
					CBaseEntity@ pPlayerToFollow = null;

					if ( args[2] == "me" )
					{
						@pPlayerToFollow = talker;
					}
					else 
					{
						@pPlayerToFollow = UTIL_FindPlayer(args[2]);
					}

					if ( pPlayerToFollow !is null && pPlayerToFollow !is m_pPlayer )
					{
						RCBotSchedule@ sched = SCHED_CREATE_NEW();
						RCBotTask@ task = SCHED_CREATE_PATH(vTalker,talker);

						sched.addTask(task);
						sched.addTask(CBotTaskFollow(pPlayerToFollow,false));
						OK = true;
					}
				}				
			}
			else if ( args[1] == "heal" )
			{
				bBotHeard = true;

				if ( args.length() > 2 )
				{
					CBaseEntity@ pPlayerToHeal = null;

					if ( args[2] == "me" )
					{
						@pPlayerToHeal = talker;
					}
					else 
					{
						@pPlayerToHeal = UTIL_FindPlayer(args[2]);
					}

					if ( pPlayerToHeal !is null && pPlayerToHeal !is m_pPlayer )
					{
						RCBotSchedule@ sched = SCHED_CREATE_NEW();
						RCBotTask@ task = SCHED_CREATE_PATH(vTalker,talker);

						sched.addTask(task);
						sched.addTask(CBotTaskHealPlayer(pPlayerToHeal));
						OK = true;
					}
				}
			}
			else if ( args[1] == "revive" )
			{
				bBotHeard = true;

				if ( args.length() > 2 )
				{
					CBaseEntity@ pPlayerToRevive = null;

					if ( args[2] == "me" )
					{
						@pPlayerToRevive = talker;
					}
					else 
					{
						@pPlayerToRevive = UTIL_FindPlayer(args[2]);
					}

					if ( pPlayerToRevive !is null && pPlayerToRevive !is m_pPlayer  )
					{
						if ( pPlayerToRevive.pev.deadflag >= DEAD_RESPAWNABLE )
						{
							RCBotSchedule@ sched = SCHED_CREATE_NEW();
							RCBotTask@ task = SCHED_CREATE_PATH(vTalker,talker);

							sched.addTask(task);
							sched.addTask(CBotTaskRevivePlayer(pPlayerToRevive));
							OK = true;
						}
					}
				}
			}			
			else if ( args[1] == "pickup" )
			{
				bBotHeard = true;

				if ( args.length() > 3 )
				{
					RCBotSchedule@ sched = SCHED_CREATE_NEW();
					RCBotTask@ task = SCHED_CREATE_PATH(vTalker);

					if ( task !is null )
					{
						sched.addTask(task);									
						
						
						if ( args[3] == "ammo" )
						{
							sched.addTask(CFindAmmoTask());
							OK = true;
						}
						else if ( args[3] == "weapon" )
						{
							sched.addTask(CFindWeaponTask());
							OK = true;
						}
						else if ( args[3] ==  "health")
						{
							sched.addTask(CFindHealthTask());
							OK = true;
						}
						else if ( args[3] ==  "armor")
						{
							sched.addTask(CFindArmorTask());
							OK = true;
						}
					
					}
				}
			}
		
			if ( bBotHeard )
			{
				if ( OK )
					Say("AFFIRMATIVE");
				else 
					Say("NEGATIVE");		
			}
		}

	}

	bool previousWaypointValid ()
	{
		return m_iPreviousWaypoint != -1;
	}

	Vector previousWaypointPosition ()
	{
		return g_Waypoints.getWaypointAtIndex(m_iPreviousWaypoint).m_vOrigin;
	}


	Vector getOrigin ()
	{
		return m_pPlayer.pev.origin;
	}


	string GetDebugMessage ()
	{
		string task = "null";
		
		if ( m_pCurrentSchedule !is null )
			task = m_pCurrentSchedule.getCurrentTask();

		string message = "Debugging: " + m_pPlayer.pev.netname;

		message += "\nTask: " + task;

		message += "\nGoal: " + m_iGoalWaypoint;
		
		if ( m_pUseBelief.GetBool() )
		 message += "[" + m_fBelief.getBeliefPercent(m_iGoalWaypoint) + " danger]";		

		if ( m_pNextWpt !is null )
		{
			message += "\nNext Wpt: " + m_pNextWpt.iIndex;
			
			if ( m_pUseBelief.GetBool() )
			 	message += "[" +m_fBelief.getBeliefPercent(m_pNextWpt.iIndex) + " danger]";	


		}

		if ( m_iCurrentWaypoint != -1 )
		{
			CWaypoint@ pWpt = g_Waypoints.getWaypointAtIndex(m_iCurrentWaypoint);
			 message += "\nCurrent Wpt: " + m_iCurrentWaypoint;
			
		     message += " (distance = " + distanceFrom(pWpt.m_vOrigin) + ")";

			 Vector m_vOrigin = m_pPlayer.pev.origin;

			 CBasePlayer@ lp = ListenPlayer();

			 if ( lp !is null )
			{
				 drawBeam(lp,m_vOrigin,pWpt.m_vOrigin,WptColor(200,200,200));
			}
		}

		message += "\nEnemy: ";

		if ( m_pEnemy.GetEntity() !is null )
		{
			CBaseEntity@ pEnemy = m_pEnemy.GetEntity();

			message += pEnemy.GetClassname();
		}
		else 
			message += "none";

		message += "\nEnemies Visible = " + m_pEnemiesVisible.EnemiesVisible();

		message += "\nHealth: " + (HealthPercent()*100) + "%";		
		message += "\nArmor: " + (ArmorPercent()*100) + "%";		

		message += "\nSpeed: ";

		if ( m_fDesiredMoveSpeed == 0 )
			message += "100%";
		else 
			message += "" + ((m_pPlayer.pev.velocity.Length()/m_fDesiredMoveSpeed)*100) + "%";

		message += "\nNum Tasks: " + int(m_fNumTasks) + ", Failed: " + int(m_fNumTasksFailed);

		return message;
	}

	bool isEntityVisible ( CBaseEntity@ pent )
	{
		int index = pent.entindex();

		return m_pVisibles.isVisible(index)>0;
	}

    // anggara_nothing  
	void ClientCommand ( string command )
	{
		CBasePlayer@ pPlayer = m_pPlayer;

		NetworkMessage m(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, pPlayer.edict());
			m.WriteString( command );
		m.End();

		//g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, command );		
	}

	float HealthPercent ()
	{
		return (float(m_pPlayer.pev.health))/m_pPlayer.pev.max_health;
	}

	float ArmorPercent ()
	{
		return (float(m_pPlayer.pev.armorvalue))/m_pPlayer.pev.armortype;
	}	

	float totalHealth ()
	{
		return (float(m_pPlayer.pev.health + m_pPlayer.pev.armorvalue))/(m_pPlayer.pev.max_health + m_pPlayer.pev.armortype);
	}

	bool BreakableIsEnemy ( CBaseEntity@ pBreakable )
	{
	//	BotMessage("BreakableIsEnemy()");
	// i. explosives required to blow breakable
	// ii. OR is not a world brush (non breakable) and can be broken by shooting
		if ( ((pBreakable.pev.flags & FL_WORLDBRUSH) != FL_WORLDBRUSH) && ((pBreakable.pev.spawnflags & 1)!=1) )
		{
			int iClass;
			
			if ( pBreakable.pev.effects & EF_NODRAW == EF_NODRAW )
				return false;

			// this means explosives only
			if ( pBreakable.pev.spawnflags & 512 == 512 )
			{
				if ( !m_pWeapons.HasExplosives(this) )
				{
					return false;
				}
			}

			iClass = pBreakable.Classify();

			switch ( iClass )
			{
				case -1:
				case 1:
				case 2:
				case 3:
				case 10:
				case 11:
				UTIL_DebugMsg(m_pPlayer,"pBreakable.Classify() false",DEBUG_THINK);
				return false;
				default:
				break;
			}

			// forget it!!!
			if ( pBreakable.pev.health > 9999 )
			{
				UTIL_DebugMsg(m_pPlayer,"pBreakable.pev.health > 9999",DEBUG_THINK);
				return false;
			}

			if ( pBreakable.pev.target != "" )
			{
				UTIL_DebugMsg(m_pPlayer,"pBreakable.pev.target != ''",DEBUG_THINK);
				return true;
			}
				
			// w00tguy
			//if ( (iClass == -1) || (iClass == 1) || (iClass == 2) || (iClass == 3) || (iClass == 10) )
			//	return FALSE; // not an enemy

			if ( m_pBlocking.GetEntity() !is null )
			{
				if ( m_pBlocking.GetEntity() is pBreakable )
				{
					UTIL_DebugMsg(m_pPlayer,"m_pBlocking.GetEntity() is pBreakable` ",DEBUG_THINK);
					return true;
				}
			}

			
			/*
			Vector vSize = pBreakable.pev.size;
			Vector vMySize = m_pPlayer.pev.size;
			
			if ( (vSize.x >= vMySize.x) ||
				(vSize.y >= vMySize.y) ||
				(vSize.z >= (vMySize.z/2)) )
			{
				UTIL_DebugMsg(m_pPlayer,"BreakableIsEnemy() true",DEBUG_THINK);
				return* true;
			}*/

			return true;
		}

		UTIL_DebugMsg(m_pPlayer,"BreakableIsEnemy() false",DEBUG_THINK);

		return false;
	}	

	bool IsEnemy ( CBaseEntity@ entity, bool bCheckWeapons = true )
	{
		string szClassname;
		
		if ( m_pDontShoot.GetBool() )
			return false;

		szClassname = entity.GetClassname();

		if ( bCheckWeapons )
		{
			CBotWeapon@ pBestWeapon = null;

			@pBestWeapon = m_pWeapons.findBestWeapon(this,UTIL_EntityOrigin(entity),entity) ;
		//	return entity.pev.flags & FL_CLIENT == FL_CLIENT; (FOR TESTING)
			// can't attack this enemy -- maybe cos I don't have an appropriate weapon
			if ( pBestWeapon is null ) 
				return false;
		}

		//BotMessage(szClassname);

		if ( szClassname == "func_breakable" )
			return BreakableIsEnemy(entity);
		if ( szClassname == "func_guntarget" )
			return entity.pev.velocity.Length() > 0;

		if ( szClassname == "func_tank")
		{
		    CBaseTank@ pTank = cast<CBaseTank@>( entity );


// to test
			return pTank.IsBreakable() && pTank.IsPlayerAlly() == false;
		}

		if ( entity.pev.deadflag != DEAD_NO )
			return false;

		if ( entity.pev.health <= 0 )
			return false;

		if ( (entity.pev.effects & EF_NODRAW) == EF_NODRAW )
		return false; // can't see

		if ( szClassname == "hornet" )
			return false;

		if ( szClassname == "monster_tentacle" ) // tentacle things dont die
			return false;

		if ( szClassname == "monster_gargantua" )
			return !entity.IsPlayerAlly();

		if ( (entity.pev.flags & FL_MONSTER) == FL_MONSTER )
		{

				//http://www.svencoop.com/manual/classes.html
				switch ( entity.Classify() )
		{
case 	CLASS_FORCE_NONE	:
case 	CLASS_NONE	:
case 	CLASS_PLAYER	:

case 	CLASS_ALIEN_PASSIVE	:
case 	CLASS_PLAYER_BIOWEAPON	:
	return false; // ignore
case 	CLASS_PLAYER_ALLY	:
case 	CLASS_HUMAN_PASSIVE	:
	
	return false; // ally
case 	CLASS_INSECT	:
if ( szClassname == "monster_leech" )
		{
			if ( entity.pev.waterlevel > 0 && m_pPlayer.pev.waterlevel > 0 )
			{
				if ( distanceFrom(entity) < 64 )
				{
					// may be blocking the way, smack it!
					return true;
				}
			}
		}
		return false;
case 	CLASS_ALIEN_BIOWEAPON	:
case 	CLASS_MACHINE	:
case 	CLASS_HUMAN_MILITARY	:
case 	CLASS_ALIEN_MILITARY	:
case 	CLASS_ALIEN_MONSTER	:
case 	CLASS_ALIEN_PREY	:
case 	CLASS_ALIEN_PREDATOR	:
case 	CLASS_XRACE_PITDRONE	:
case 	CLASS_XRACE_SHOCK	:
case 	CLASS_BARNACLE	:

		if ( szClassname == "monster_turret" || szClassname == "monster_miniturret" )
		{
			// turret is invincible when closed
			if ( entity.pev.sequence == 0 )
				return false;
		}
return true;
		}
			}

			return false;
	}

	bool hasEnemy ()
	{
		return m_pEnemy.GetEntity() !is null;
	}

	CBaseEntity@ getEnemy ()
	{
		return m_pEnemy.GetEntity();
	}

	bool canGotoWaypoint ( CWaypoint@ currWpt, CWaypoint@ succWpt )
	{
		if ( succWpt.hasFlags(W_FL_CROUCHJUMP) )
		{
			// this waypoint requires the long jump modules
			if ( m_pPlayer.m_fLongJump == false )
				return false;
		}
		if ( m_bLastPathFailed )
		{
			if ( currWpt.iIndex == m_iLastWaypointFrom && succWpt.iIndex == m_iLastWaypointTo )
				return false;
		}
		if ( succWpt.hasFlags(W_FL_UNREACHABLE) )
			return false;
		if ( succWpt.hasFlags(W_FL_GRAPPLE) )
		{
			if ( !HasWeapon("weapon_grapple") )	
				return false;
		}
		if ( succWpt.hasFlags(W_FL_CHECK_GROUND) )
		{
			TraceResult tr;

			g_Utility.TraceLine( succWpt.m_vOrigin, succWpt.m_vOrigin - Vector(0,0,64.0f), ignore_monsters,dont_ignore_glass, null, tr );
			
			// no ground?
			if ( tr.flFraction >= 1.0f )
				return false;

		}
		if ( succWpt.hasFlags(W_FL_OPENS_LATER) )
		{								
			TraceResult tr;

			g_Utility.TraceLine( currWpt.m_vOrigin, succWpt.m_vOrigin, ignore_monsters,dont_ignore_glass, null, tr );

			if ( tr.flFraction < 1.0f )
			{
				if ( tr.pHit is null )
					return false;
			
				CBaseEntity@ ent = g_EntityFuncs.Instance(tr.pHit);

				// mght be closed but is not locked
				if ( ent.GetClassname() == "func_door" || ent.GetClassname() == "func_door_rotating" )
				{
					CBaseDoor@ door = cast<CBaseDoor@>( ent );

					if ( !UTIL_DoorIsOpen(door,m_pPlayer) )
					{
						//BotMessage("UTIL_DoorIsOpen() == false");
						return false;
					}
				}
				else
					return false;
			}		
			else
			{
				CBaseEntity@ pent = null;
				bool bFound = false;
				Vector vSucc = succWpt.m_vOrigin;		

				while ( (@pent =  g_EntityFuncs.FindEntityByClassname(pent, "trigger_push")) !is null )
				//while ( (@pent = g_EntityFuncs.FindEntityInSphere(pent, succWpt.m_vOrigin , 128,"trigger_hurt", "classname"  )) !is null )
				{										
						if ( ((pent.pev.spawnflags & 8)!=8) && (pent.pev.solid == SOLID_TRIGGER) )
						{
							if ( UTIL_VectorInsideEntity(pent,vSucc) || ((UTIL_EntityOrigin(pent)-vSucc).Length() < 128) )
							{
								//BotMessage("TRIGGET PUSH DETECTED!!!");
								bFound = true;
								break;	
							}

							//BotMessage("TRIGGET PUSH DETECTED!!! 1");
						}

						//BotMessage("TRIGGET PUSH DETECTED!!! 2");
				}


				if ( bFound )
					return false;
									
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
						if ( UTIL_VectorInsideEntity(pent,vSucc) || ((UTIL_EntityOrigin(pent)-vSucc).Length() < 128) )
						{
							//BotMessage("TRIGGET HURT DETECTED!!!");
							bFound = true;
							break;	
						}

						//BotMessage("TRIGGET HURT DETECTED!!! 1");
					}

					//BotMessage("TRIGGET HURT DETECTED!!! 2");
			}

			if ( bFound )
				return false;
											
		}

		//if ( (iSucc != m_iGoalWaypoint) && !m_pBot.canGotoWaypoint(vOrigin,succWpt,currWpt) )
	//		continue;
		if ( currWpt.hasFlags(W_FL_WATER) )
		{
			if ( g_EngineFuncs.PointContents(currWpt.m_vOrigin) != CONTENTS_WATER )
				return false;
		}

		if ( currWpt.hasFlags(W_FL_TELEPORT) )
		{
			if ( !UTIL_DoesNearestTeleportGoTo(currWpt.m_vOrigin,succWpt.m_vOrigin) )
			{
				//BotMessage("WAYPINT DOESN'T GO TO THIS TELEPORT!!! SKIPPING!!!");
				return false;
			}
		}

		return true;
			
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

	void addToSchedule ( RCBotTask@ task )
	{
			if ( m_pCurrentSchedule is null )
				m_pCurrentSchedule = RCBotSchedule();
			
			m_pCurrentSchedule.addTaskFront(task);		
	}

	/**
	 * @return the number of times the route stack may be popped
	*/
	int touchedWpt ( CWaypoint@ wpt, CWaypoint@ pNextWpt, CWaypoint@ pThirdWpt )                       
	{
		UTIL_DebugMsg(m_pPlayer,"touchedWpt()",DEBUG_NAV);

		if ( pThirdWpt !is null )
			@m_pNextWpt = pThirdWpt;
		else
			@m_pNextWpt = null;		

		if ( pNextWpt !is null )
		{					
			m_iLastWaypointFrom = wpt.iIndex;
			m_iLastWaypointTo = pNextWpt.iIndex;

			if ( pThirdWpt !is null )
			{
				bool bIsUp = pThirdWpt.m_vOrigin.z > wpt.m_vOrigin.z;

				// goind down - look at thrid waypoint if not ladder
				if ( bIsUp == false )
				{
					if ( !pThirdWpt.hasFlags(W_FL_LADDER) )
						m_vLadderVector = pThirdWpt.m_vOrigin;
				}
				else if ( pNextWpt.hasFlags(W_FL_LADDER) && !wpt.hasFlags(W_FL_LADDER) && pThirdWpt.hasFlags(W_FL_LADDER) ) 
				{					
					// Make a ladder component vector for bots to look at
					// while climbing 
					// the angle will be 45 degrees up/down
					
					Vector vLadderComp = (pNextWpt.m_vOrigin - wpt.m_vOrigin);
					float fLadderHeight = abs(pThirdWpt.m_vOrigin.z - pNextWpt.m_vOrigin.z);
					fLadderHeight/=8;
										
					// nullify height
					vLadderComp.z = 0;
					// normalize
					vLadderComp = vLadderComp/vLadderComp.Length();
					// add component
					// bots will look at this vector when climbing

					m_vLadderVector = pThirdWpt.m_vOrigin + (vLadderComp*fLadderHeight);

					//drawBeam (ListenPlayer(), m_pPlayer.pev.origin, m_vLadderVector, WptColor(255,255,255,255), 50 );

				}
			}
			else
			{
				if ( !pNextWpt.hasFlags(W_FL_LADDER) )
					m_vLadderVector = pNextWpt.m_vOrigin;
			}

			if ( pNextWpt.hasFlags(W_FL_GRAPPLE) )
			{
				if ( pThirdWpt !is null )
				{			
					grapple(pNextWpt.m_vOrigin,pThirdWpt.m_vOrigin);

					// pop the current and next two waypoints
					return 3;
				}
			}
			// Wait No player waypoint 
			else if( pNextWpt.hasFlags(W_FL_WAIT_NO_PLAYER) )
			{
				if ( m_pCurrentSchedule is null ) // create new schedule if none exists
					m_pCurrentSchedule = RCBotSchedule();
				
				m_pCurrentSchedule.addTaskFront(CBotTaskWaitNoPlayer(pNextWpt.m_vOrigin));
			}			
		}
		if ( wpt.hasFlags(W_FL_LIFT) )
		{
			// find platform
			if ( m_pPlayer.pev.groundentity !is null )
			{
				CBaseEntity@ pGroundEnt = g_EntityFuncs.Instance(m_pPlayer.pev.groundentity);

				if ( pGroundEnt !is null )
				{
					CBaseToggle@ pDoor = cast<CBaseToggle@>(pGroundEnt);

					if ( pDoor !is null )
					{
						//classname, Vector vOrigin, float fMinDist, bool checkFrame, bool bVisible
						CBaseEntity@ pButton = UTIL_FindNearestEntity("func_button",m_pPlayer.pev.origin,200.0f,false,true);

						if ( pButton !is null )
							pressButton(pButton);
						else 
							BotMessage("pButton null");
					}
					else 
							BotMessage("pDoor null");
				}
				else 
					BotMessage("pGroundEnt instance null");

			}
			else 
					BotMessage("pGroundEnt instance null");
		}
		if ( wpt.hasFlags(W_FL_WAIT) )
		{
			if ( m_pCurrentSchedule is null )
				m_pCurrentSchedule = RCBotSchedule();

				Vector vface = wpt.m_vOrigin;

				if ( pNextWpt !is null )
				{
					vface = pNextWpt.m_vOrigin;
					//BotMessage("VFACE = NEXT WPT");
				}
			
			m_pCurrentSchedule.addTaskFront(CBotTaskWait(1.75f,vface));
		}
		if ( wpt.hasFlags(W_FL_TELEPORT) )
		{
			if ( m_pCurrentSchedule is null )
				m_pCurrentSchedule = RCBotSchedule();
			
			if ( pNextWpt !is null )
			{
				Vector vNextWpt = pNextWpt.m_vOrigin;
				m_pCurrentSchedule.addTaskFront(CBotTaskUseTeleporter(wpt.m_vOrigin,vNextWpt));			
				//BotMessage("GOING TO USE TELEPORTER...");
			}

			
		}

		if ( wpt.hasFlags(W_FL_JUMP) )
			Jump();
		if ( wpt.hasFlags(W_FL_CROUCHJUMP) )
		{
			if ( m_pNextWpt !is null )
			{			
				// need this
				addToSchedule(CLongjumpTask(m_pNextWpt.m_vOrigin));
				BotMessage("Long JUmp!\r\n");	
			}
			else// just jump --- and fall !!!
			{
				Jump(); // dooooooh!
				BotMessage("Nooooo!\r\n");
			}
		}
		

		if( wpt.hasFlags(W_FL_HUMAN_TOWER) && m_pNextWpt !is null )
		{
			addToSchedule(CBotHumanTowerTask(wpt.m_vOrigin,m_pNextWpt.m_vOrigin,m_pNextWpt.m_iFlags));
		}

		if ( pThirdWpt !is null )
		{
			if ( pNextWpt !is null )
			{
				if ( !wpt.hasFlags(W_FL_PLATFORM) )
				{
					// If need to wait for platform or jump to platform, wait
					if (!wpt.hasFlags(W_FL_JUMP) && pNextWpt.hasFlags(W_FL_PLATFORM) )
					{
						addToSchedule(CBotWaitPlatform(pNextWpt.m_vOrigin));

						return 1;
					}
					else if ( pThirdWpt.hasFlags(W_FL_PLATFORM) && pNextWpt.hasFlags(W_FL_JUMP) )
					{
						addToSchedule(CBotWaitPlatform(pThirdWpt.m_vOrigin));

						return 1;					
					}
				}
			}
		}

		// pop only one waypoint
		return 1;
	}
	

	WptColor@ col = WptColor(255,255,255);

	void followingWpt ( Vector vOrigin, int flags )
	{
		if ( (flags & W_FL_PLATFORM) == W_FL_PLATFORM )
		{
			if ( m_pPlayer.pev.groundentity !is null )
			{
				CBaseEntity@ pGroundEnt = g_EntityFuncs.Instance(m_pPlayer.pev.groundentity);

				if ( pGroundEnt !is null )
				{
					// on a lift / platform - don't move
					if ( pGroundEnt.pev.velocity.Length() > 0 )
					{
						TraceResult tr;

						g_Utility.TraceLine( vOrigin, vOrigin-Vector(0,0,64), ignore_monsters,dont_ignore_glass, m_pPlayer.edict(), tr );

						if ( tr.pHit !is pGroundEnt.edict() )
						{
							// move to centre of platform and stop moving
							Vector vCentre = UTIL_EntityOrigin(pGroundEnt);
							vCentre.z = m_pPlayer.pev.origin.z;

							if ( (m_pPlayer.pev.origin - vCentre).Length() > 48 )
								setMove(vCentre);
							else 
								StopMoving();
							//BotMessage("WptDist >>>>");
							return;
						}

						//else
						//	BotMessage("WptDist <<<");
					}
				}
			}			
		}

		if ( (flags & W_FL_CROUCH) == W_FL_CROUCH )
			PressButton(IN_DUCK);

		if ( IsOnLadder() || ((flags & W_FL_LADDER) == W_FL_LADDER) )
		{
			UTIL_DebugMsg(m_pPlayer,"IN_FORWARD",DEBUG_NAV);
			setLookAt(vOrigin);
			PressButton(IN_FORWARD);

			const int FALL_DISTANCE = 64;

			 if ((flags & W_FL_LADDER) != W_FL_LADDER)
			 {
				// We are above next waypoint by less than FALL_DISTANCE
				// Just jump off
				if ( (vOrigin.z < m_pPlayer.pev.origin.z) && (vOrigin.z + FALL_DISTANCE) > m_pPlayer.pev.origin.z )
				{
					Jump();
				}
			 }
		}

		if ( (flags & W_FL_STAY_NEAR) == W_FL_STAY_NEAR )
			setMoveSpeed(m_pPlayer.pev.maxspeed/4);

		//BotMessage("Following Wpt");	
		
		setMove(vOrigin);

		//drawBeam (ListenPlayer(), m_pPlayer.pev.origin, wpt.m_vOrigin, col, 1 );

	}

	float m_fListenDistance = 768.0f;

	void DoListen ()
	{	
		CBaseEntity@ pEnemy = m_pEnemy.GetEntity();
		CBaseEntity@ pNearestPlayer = null;
		float m_fNearestPlayer = m_fListenDistance;
		
		if ( pEnemy !is null )
			return;


		for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

			if( pPlayer is null )
				continue;

			if ( pPlayer == m_pPlayer )
				continue;

			if ( UTIL_PlayerIsAttacking(pPlayer) )
			{
				float fDistance = distanceFrom(pPlayer);

				if ( fDistance < m_fNearestPlayer )
				{
					m_fNearestPlayer = fDistance;
					@pNearestPlayer = pPlayer;
				}
			}
		}

		if ( pNearestPlayer !is null  )
		{

					if ( isEntityVisible(pNearestPlayer) )
						seePlayerAttack(pNearestPlayer);
					else
						hearPlayerAttack(pNearestPlayer	);			
		}
	}

	void hearPlayerAttack ( CBaseEntity@ pPlayer )
	{
		if ( !hasHeardNoise() || (m_pListenPlayer.GetEntity() !is pPlayer) )
			checkoutNoise(pPlayer,false);		
	}

	void seePlayerAttack ( CBaseEntity@ pPlayer )
	{
		checkoutNoise(pPlayer,true);		
	}

	void checkoutNoise ( CBaseEntity@ pPlayer, bool visible )
	{
		m_pListenPlayer = pPlayer;
		m_flHearNoiseTime = g_Engine.time + 3.0;
		m_vNoiseOrigin = pPlayer.EyePosition();

		if ( visible )
		{
			// Ok set noise to forward vector
			g_EngineFuncs.MakeVectors(pPlayer.pev.v_angle);

			m_vNoiseOrigin = m_vNoiseOrigin + g_Engine.v_forward * 2048.0f;					
		}
	}

	bool bWaiting = false;

	RCBotSchedule@ SCHED_CREATE_NEW ()
	{
		@m_pCurrentSchedule = RCBotSchedule();

		return m_pCurrentSchedule;
	}


	RCBotTask@ SCHED_CREATE_PATH ( Vector vOrigin, CBaseEntity@ pentTarget = null )
	{
		int iWpt = g_Waypoints.getNearestWaypointIndex(vOrigin);
		
		if ( iWpt == -1 )
			return null;
		
		return CFindPathTask(this,iWpt,pentTarget);
	}

	// press button and go back to original waypoint
	void pressButton ( CBaseEntity@ pButton, int iLastWpt=-1, bool findPath = false )
	{
		int iWpt = -1;

		if ( findPath )
		{
			//CFindPathTask ( RCBot@ bot, int wpt, CBaseEntity@ pEntity = null )
			iWpt = g_Waypoints.getNearestWaypointIndex(UTIL_EntityOrigin(pButton),pButton);
			
			if ( iWpt == -1 )
			{
				UTIL_DebugMsg(m_pPlayer,"pressButton() NO PATH",DEBUG_THINK);
				return;
			}
		}

		// don't overflow tasks
		if ( m_pCurrentSchedule.numTasksRemaining() < 5 )
		{
			if ( findPath )
			{
				// This will be the third task
				m_pCurrentSchedule.addTaskFront(CFindPathTask(this,iLastWpt));
			}
			// This will be the second task
			m_pCurrentSchedule.addTaskFront(CUseButtonTask(pButton));

			if ( findPath )
			{
				// This will be the first task
				m_pCurrentSchedule.addTaskFront(CFindPathTask(this,iWpt,pButton));
			}
			

			UTIL_DebugMsg(m_pPlayer,"pressButton() OK",DEBUG_THINK);
		}
		else
		{
			UTIL_DebugMsg(m_pPlayer,"pressButton() overflow",DEBUG_THINK);
		}
	}

	bool hasHeardNoise ()
	{
		return (m_flHearNoiseTime > g_Engine.time);
	}

	CBotWeapon@ getCurrentWeapon ()
	{
		return m_pWeapons.getCurrentWeapon();
	}

	bool isCurrentWeapon ( CBotWeapon@ weap )
	{
		return m_pWeapons.m_pCurrentWeapon is weap;
	}

	CBotWeapon@ getMedikit ()
	{
		return m_pWeapons.findBotWeapon("weapon_medkit");
	}	

	CBotWeapon@ getGrapple ()
	{
		return m_pWeapons.findBotWeapon("weapon_grapple");
	}	

	
	CBotWeapon@ getGrenade ()
	{
		return m_pWeapons.findBotWeapon("weapon_handgrenade");
	}	


	CBotWeapon@ getExplosives ()
	{
		return m_pWeapons.findBotWeapon("weapon_explosive");
	}			

	CBotWeapon@ getTripmines ()
	{
		return m_pWeapons.findBotWeapon("weapon_tripmine");
	}	

	void selectWeapon ( CBotWeapon@ weapon )
	{
		m_pWeapons.selectWeapon(this,weapon);
	}

	bool CanRevive ( CBaseEntity@ entity )
	{
        CBotWeapon@ medikit = getMedikit();

        if ( medikit is null )
            return false;

		if ( medikit.getPrimaryAmmo(this) < 50 )
			return false;
	
		if ( (entity.pev.flags & FL_MONSTER) == FL_MONSTER )
		{
			if ( m_pReviveNPC.GetBool() )
			{				
				if ( !entity.IsPlayerAlly() )	
				{
					return false;
				}

				if ( !UTIL_MonsterIsHealable(entity) )			
					return false;							
			}
		}	
		else
		{
			if ( (entity.pev.flags & FL_CLIENT) != FL_CLIENT )	
				return false;
		}
		if ( entity.pev.deadflag != DEAD_RESPAWNABLE )
			return false;

// probably a spectator
		if ( entity.pev.effects & EF_NODRAW == EF_NODRAW )
		{
			return false;
		}			

		return true;
	}

	bool CanHeal ( CBaseEntity@ entity )
	{
        // select medikit
        CBotWeapon@ medikit = getMedikit();

        if ( medikit is null )
		{
			BotMessage("medikit == null");
            return false;
		}

		if ( (entity.pev.flags & FL_MONSTER) == FL_MONSTER )
		{
			if ( m_pHealNPC.GetBool() )
			{						
				if ( !entity.IsPlayerAlly() )	
				{
					return false;
				}

				if ( !UTIL_MonsterIsHealable(entity) )			
					return false;
			}
		}	
		else
		{
			if ( (entity.pev.flags & FL_CLIENT) != FL_CLIENT )	
				return false;
		}

		if ( (entity.pev.flags & FL_GODMODE) == FL_GODMODE )
			return false;
// probably a spectator
		if ( (entity.pev.effects & EF_NODRAW) == EF_NODRAW )
		{
			return false;
		}

		// can't heal the dead -- revive will be done separately
		if ( entity.pev.deadflag != DEAD_NO )
			return false;

        if ( medikit.getPrimaryAmmo(this) == 0 )
        {
            return false;
        }

		UTIL_DebugMsg(m_pPlayer,"CanHeal("+entity.GetClassname()+")",DEBUG_THINK);

		return (entity.pev.health < entity.pev.max_health);
	}

	float getHealFactor ( CBaseEntity@ player )
	{
		return distanceFrom(player) * (1.0 - (float(player.pev.health) / player.pev.max_health));
	}

	void reachedGoal()
	{
		m_fBelief.safety(m_iCurrentWaypoint,50.0f);
		UTIL_DebugMsg(m_pPlayer,"Safety added to goal/current waypoint",DEBUG_BELIEF);

		m_fNextTakeCover = g_Engine.time;
	}

	void TakeCoverFromGrenade ( CBaseEntity@ pGrenade )
	{
		if ( m_fNextTakeCover < g_Engine.time )
		{
			@m_pCurrentSchedule = CBotTaskFindCoverSchedule(this,UTIL_GrenadeEndPoint(pGrenade));
			m_fNextTakeCover = g_Engine.time + Math.RandomFloat(6.0,12.0);
			ShoutTakeCover();
		}			
	}

	void TakeCover ( Vector vOrigin )
	{
		if ( m_fNextTakeCover < g_Engine.time )
		{
			@m_pCurrentSchedule = CBotTaskFindCoverSchedule(this,vOrigin);
			m_fNextTakeCover = g_Engine.time + Math.RandomFloat(6.0,12.0);
		}			
	}

	void Say (string text)
	{
		g_PlayerFuncs.SayTextAll(m_pPlayer,"[RCBOT] " + m_pPlayer.pev.netname + ": \"" + text + "\"");
	}

	float m_fLastHurt = 0.0f;
	Vector m_vHurtOrigin;

	void hurt ( DamageInfo@ damageInfo )
	{
		CBaseEntity@ attacker = damageInfo.pAttacker;
		
		if ( attacker !is null )
		{
			Vector vAttacker = UTIL_EntityOrigin(attacker);

			if ( damageInfo.flDamage < 0.0 )
				BotMessage("Heal?");
			//BotMessage("Hurt!");

			if ( isEntityVisible(attacker) )
			{
				TakeCover(vAttacker);
				m_fLastHurt = 0.0f;
			
				//BotMessage("Take Cover!!!");
			}
			else
			{
				m_vHurtOrigin = vAttacker;
				m_fLastHurt = g_Engine.time + 3.0f;
				//BotMessage("Look!!!");
			}

			m_fBelief.danger(m_iCurrentWaypoint,vAttacker,10);
			//UTIL_DebugMsg(m_pPlayer,"Danger added to current waypoint",DEBUG_BELIEF);			
		}
	}

	void Think()
	{		
		//if ( m_fNextThink > g_Engine.time )
		//	return;

		// make bots randomly alter thinking time
		//m_fNextThink = g_Engine.time + Math.RandomFloat(0.5,1.5);

		/*

		CSoundEnt@ soundEnt = GetSoundEntInstance();
		int iSound = m_pPlayer.m_iAudibleList;

		while ( iSound != SOUNDLIST_EMPTY )
		{
			CSound@ pCurrentSound = soundEnt.SoundPointerForIndex( iSound );

			if ( pCurrentSound is null )
			{
				break;
			}

			if ( pCurrentSound.FIsSound() )
			{
				BotMessage("SOUND TYPE = " + pCurrentSound.m_iType + " Volume = " + pCurrentSound.m_iVolume);
			}

			iSound = pCurrentSound.m_iNext;
		}*/

		m_iLookPriority = 0;
		m_bMoveToValid = false;

		CBaseEntity@ pLastEnemy = m_pLastEnemy.GetEntity();

		if ( pLastEnemy !is null )
		{
			if ( !IsEnemy(pLastEnemy) )
			{
				// enemy probably dead now
				m_fBelief.safety(m_iCurrentWaypoint,20.0f);
				UTIL_DebugMsg(m_pPlayer,"Safety added to current waypoint",DEBUG_BELIEF);
				RemoveLastEnemy();
			}
		}

		int light_level = g_EngineFuncs.GetEntityIllum(m_pPlayer.edict());

		if ( !m_pPlayer.FlashlightIsOn() )
		{
			if ( light_level < 10 )
			{
				if ( m_pPlayer.m_iFlashBattery > 50 )
				{
					m_pPlayer.FlashlightTurnOn();
				}
			}
		}
		else
		{
			// flashlight on
			if ( light_level > 90 )
			{
				m_pPlayer.FlashlightTurnOff();				
			}
		}
		
		ceaseFire(false);

		m_iCurrentPriority = PRIORITY_NONE; // reset move/look priority
		m_pWeapons.updateWeapons(this); // keep weapons up to date this frame

		ReleaseButtons(); // let go of all buttons - these will be updated later

		m_fDesiredMoveSpeed = m_pPlayer.pev.maxspeed; // assume bot wants to move - until set by move look

		BotManager::BaseBot::Think(); // do base think stuff
		
		//If the bot is dead and can be respawned, send a button press to respawn
		if( Player.pev.deadflag >= DEAD_RESPAWNABLE )
		{
			// don't press attack if we're dead and it's survival mode
			//if ( g_SurvivalMode.IsEnabled() && g_SurvivalMode.IsActive() )
			{
				if( Math.RandomLong( 0, 100 ) > 10 )
					PressButton(IN_ATTACK);

				SpawnInit();
			}

			return; // Dead , nothing else to do
		}

		m_iPrevHealthArmor = m_iCurrentHealthArmor; // keep track of how much armor we have

		init = false; // we have already spawned

		if ( m_pEnemy.GetEntity()  !is null ) // keep checking current enemy
		{
			if ( !IsEnemy(m_pEnemy.GetEntity() ) ) // is it still an enemy?
				m_pEnemy = null; // clear the enemy
		}
		/*
		KeyValueBuffer@ pInfoBuffer = g_EngineFuncs.GetInfoKeyBuffer( Player.edict() );
		
		pInfoBuffer.SetValue( "topcolor", Math.RandomLong( 0, 255 ) );
		pInfoBuffer.SetValue( "bottomcolor", Math.RandomLong( 0, 255 ) );

		pInfoBuffer.SetValue( "rate", 3500 );
		pInfoBuffer.SetValue( "cl_updaterate", 20 );
		pInfoBuffer.SetValue( "cl_lw", 1 );
		pInfoBuffer.SetValue( "cl_lc", 1 );
		pInfoBuffer.SetValue( "cl_dlmax", 128 );
		pInfoBuffer.SetValue( "_vgui_menus", 0 );
		pInfoBuffer.SetValue( "_ah", 0 );
		pInfoBuffer.SetValue( "dm", 0 );
		pInfoBuffer.SetValue( "tracker", 0 );
		
		if( Math.RandomLong( 0, 100 ) > 10 )
			Player.pev.button |= IN_ATTACK;
		else
			Player.pev.button &= ~IN_ATTACK;
			
		for( uint uiIndex = 0; uiIndex < 3; ++uiIndex )
		{
			m_vecVelocity[ uiIndex ] = Math.RandomLong( -50, 50 );
		}*/
		DoTasks(); // do schedule/tasks 
		DoVisibles(); // update visible list

		DoListen(); // update nearby listenable objects

		DoMove(); // update move command
		DoLook(); // update look command

		DoWeapons(); // update weapon/attack commands
		DoButtons(); // update button presses

		
		
	}

	bool m_bReEvaluateUtility = false;
	
	float m_fNumTasks = 0;
	float m_fNumTasksFailed = 0;
	float m_fTaskFailTime = 0.0f;

	EHandle m_pBlocking = null; // blocking object

	float m_fHandleBlockedByPlayer = 0;

	void setBlockingEntity ( CBaseEntity@ blockingEntity ) 
	{
		m_pBlocking = blockingEntity;

		if ( blockingEntity !is null )
		{
			if ( blockingEntity.pev.flags & FL_CLIENT == FL_CLIENT )
			{
				// a player is blocking the way
				// decide whether to move 
				setAvoiding(m_pBlocking);
				/*
				if ( m_fHandleBlockedByPlayer < g_Engine.time )
				{
					m_fHandleBlockedByPlayer = g_Engine.time + RandomFloat(10.0f,20.0f);

					
				}*/
			}

		}
	}

	void DoWeapons ()
	{	
		if ( !ceasedFiring() ) // only do weapons if not told to cease fire by task
			m_pWeapons.DoWeapons(this,m_pEnemy);
	}

	/** Smaller factors are better */
	float getEnemyFactor ( CBaseEntity@ entity )
	{
		float fFactor = distanceFrom(entity.pev.origin) * entity.pev.size.Length();
			
		// focus on nearly dead enemies
		fFactor += entity.pev.health;

		if ( entity.GetClassname() == "func_breakable" ) // less emphasis on breakables - focus more on things that can hurt us
			fFactor *= 2;
		else if ( entity.GetClassname() == "func_guntarget")
			fFactor *= 10; // pose no threat
		else if ( entity.GetClassname() == "monster_male_assassin" || entity.GetClassname() == "monster_hwgrunt" )
			fFactor /= 2; // focus more on stronger enemies

		return fFactor;
	}

	float getEnemyDanger ( Vector position )
	{
		return m_pEnemiesVisible.getDanger(position);
	}
	// we got a new visible event
	void newVisible ( CBaseEntity@ ent )
	{
		if ( ent is null ) // probably shouldnt happen but may have seen it before ???
		{
			// WTFFFFF!!!!!!!
			return;
		}
		if ( ent is m_pPlayer ) // avoid myself
			return;

		if ( CanHeal(ent) ) // Oh I can heal this entity?
		{
			//BotMessage("CanHeal == TRUE");
			// update the heal entity to this guy
			if ( m_pHeal.GetEntity() is null )
				m_pHeal = ent; 
			else if ( getHealFactor(ent) < getHealFactor(m_pHeal) )
				m_pHeal = ent;
		}		
		else if ( CanRevive(ent) ) // Oh I can revive this entity?
		{
			//BotMessage("CanRevive == TRUE");
			// update the revive entity to this guy
			if ( m_pRevive.GetEntity() is null )
				m_pRevive = ent; 
			else if ( getHealFactor(ent) < getHealFactor(m_pRevive) )
				m_pRevive = ent;
		}
		// Oh, this guy is an enemy?
		if ( IsEnemy(ent) )
		{
			// call new enemy event
			m_pEnemiesVisible.newEnemy(ent);

			//BotMessage("NEW ENEMY !!!  " + ent.pev.classname + "\n");
			// update the last time I saw an enemy
			m_fLastSeeEnemyTime = g_Engine.time;
		}
		// Oh I see a tank I could control?
		if ( ent.GetClassname() == "func_tank" )
		{
			if ( UTIL_CanUseTank(m_pPlayer,ent) )
			{
				setNearestTank(ent);
			}
		}
		// Oh this is a friendly player who isn't me 
		if ( (g_EntityFuncs.EntIndex(ent.edict()) > 0) && (g_EntityFuncs.EntIndex(ent.edict()) <= g_Engine.maxClients) )
		{
			CBaseEntity@ pPlayer = m_pNearestClient.GetEntity();

			if ( ent.IsPlayerAlly() ) // check he is friendly
			{
				if ( (pPlayer is null) || (distanceFrom(ent) < distanceFrom(pPlayer)) )
				{
					// update my scientist to the nearest one
					m_pNearestClient = pPlayer;
				}
			}

		}
		// Oh I see a friendly scientist?!
		if ( ent.GetClassname() == "monster_scientist" )
		{
			CBaseEntity@ pScientist = m_pLastSeenScientist.GetEntity();

			if ( ent.IsPlayerAlly() ) // check he is friendly
			{
				if ( (pScientist is null) || (distanceFrom(ent) < distanceFrom(pScientist)) )
				{
					// update my scientist to the nearest one
					m_pLastSeenScientist = ent;
				}
			}
		}
		// Oh I see a friendly barney
		if ( ent.GetClassname() == "monster_barney" || ent.GetClassname() == "monster_otis" )
		{
			CBaseEntity@ pBarney = m_pLastSeenBarney.GetEntity();
			// Make sure he is friendly
			if ( ent.IsPlayerAlly() )
			{
				if ( (pBarney is null) || (distanceFrom(ent) < distanceFrom(pBarney)) )
				{
					// update my barney to the nearest one
					m_pLastSeenBarney = ent;
				}
			}
		}	
	}
	// Lost a visible event
	void lostVisible ( CBaseEntity@ ent )
	{
		//BotMessage("lost visible\n");

		// he might have been an enemy
		m_bReEvaluateUtility = m_pEnemiesVisible.enemyLost(ent,this);

		// Todo --- Really need to clear these? I may have lost sight of them
		// But they are actually still there!!!

		// Otherwise he might have been my healable
		if ( m_pHeal.GetEntity() is ent )
		{
			m_pHeal = null;
		}
		// Maybe it was my revivable?
		if ( m_pRevive.GetEntity() is ent )
		{
			m_pRevive = null;
		}
		// Or maybe lost visibility of my tank?
		if ( m_pNearestTank.GetEntity() is ent )
		{
			m_pNearestTank = null; // Clear it
		}
		if ( m_pNearestClient.GetEntity() is ent )
		{
			m_pNearestClient = null;
		}
	}
	// Remember that I failed going some way
	void failedPath ( bool failed )
	{
		m_bLastPathFailed = failed;
	}
	// reinitialise variables at spawn
	void SpawnInit ()
	{
		if ( init == true )
			return;

		@m_pNextWpt = null;
		m_fClearAvoidTime = 0.0;
		m_fTaskFailTime = g_Engine.time + 10.0f;
		m_fNumTasks = 0;
		m_fNumTasksFailed = 0;

		m_pEnemiesVisible.clear();
		m_flJumpPlatformTime = 0;
		@m_pExpectedPlatform = null;
		m_iLastWaypointFrom = -1;
		m_iLastWaypointTo = -1;

		m_flJumpTime = 0.0f;

		m_fNextShoutMedic = 0.0f;
		m_fNextShoutTakeCover = 0.0f;
		m_fNextShout = 0.0f;

		m_pWeapons.spawnInit();
		m_iLastFailedWaypoint = -1;
		init = true;

		@m_pCurrentSchedule = null;
	//	@navigator = null;	
		m_pEnemy = null;
		
		m_pVisibles.reset();
		utils.reset();

		m_flStuckTime = 0;
		m_pHeal = null;

	}

	EHandle ignoreAvoid = null;
	float m_fClearAvoidTime = 0;

	// set ignores for things like healing players/human tower etc 
	// we want to get closer, not to avoid them
	void setIgnoreAvoid ( CBaseEntity@ ent )
	{
		ignoreAvoid = ent;
		m_fClearAvoidTime = g_Engine.time + 1.0f;
	}

	// check if I can avoid this
	bool CanAvoid ( CBaseEntity@ ent )
	{
		if ( m_fClearAvoidTime > 0 && m_fClearAvoidTime < g_Engine.time )
		{
			m_fClearAvoidTime = 0;
			ignoreAvoid = null;
		}
		if ( IsOnLadder() ) // I won't avoid while I am on a ladder
			return false;
		if ( distanceFrom(ent) > 200 ) // I can't avoid anything outside this distance
			return false;
		if ( ent == m_pPlayer ) // I can't avoid myself
			return false;
		if ( ent == ignoreAvoid.GetEntity() )
			return false;
		if ( m_pEnemy.GetEntity() is ent ) // I should probably avoid my enemy so it doesn't hit me
		{
			CBotWeapon@ pCurrentWeapon = m_pWeapons.getCurrentWeapon();

			if ( pCurrentWeapon !is null )
			{
				if ( pCurrentWeapon.IsMelee() )
					return false;
			}
		}			
		if ( (ent.pev.flags & FL_CLIENT) == FL_CLIENT ) // I can avoid players, so I don't bump into them
			return true;
		if ( (ent.pev.flags & FL_MONSTER) == FL_MONSTER ) // I should probably avoid monsters do they dont hit me
			return true;

		return false;		
	}

	void DoVisibles ()
	{
		// update visible objects
		m_pVisibles.update();
		m_pEnemy = m_pEnemiesVisible.getBestEnemy(this); // Get best enemy from within list of visible enemies

		BotEnemyLastSeen@ nearestLastSeen = m_pEnemiesVisible.nearestEnemySeen(this); // which is my nearest last seen enemy

		if ( nearestLastSeen !is null )
		{
			m_pLastEnemy = EHandle(nearestLastSeen.getEntity());
			m_vLastSeeEnemy = nearestLastSeen.getLocation();
			m_bLastSeeEnemyValid = true;
		}
		else 
		{
			m_pLastEnemy = null;
			m_bLastSeeEnemyValid = false;
		}
				
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

	float m_fStuckJumpTime = 3.0f;

	void DoMove ()
	{
		bool OnLadder = IsOnLadder();
		//if ( navigator !is null )
		//	navigator.execute(this);
		float fStuckSpeed = 0.1*m_fDesiredMoveSpeed;

		if ( OnLadder || ((m_pPlayer.pev.flags & FL_DUCKING) == FL_DUCKING) )
			fStuckSpeed /= 2;
		else if ( m_pPlayer.pev.waterlevel > 1 )
			fStuckSpeed /= 2;		
		// Can go even slower with minigun
		else if ( IsHoldingMinigun() )
			fStuckSpeed /= 3;

		// for crouch jump
		if ( m_flJumpTime + 0.5f > g_Engine.time )
		{
			if ( !OnLadder )
				PressButton(IN_DUCK);
		}

		if ( (!m_bMoveToValid || (m_pPlayer.pev.velocity.Length() > fStuckSpeed)) )
		{
			m_fStuckJumpTime = g_Engine.time + Math.RandomFloat(0.5f,1.5f);

			if ( m_bMoveToValid )
				m_fNumTasksFailed = 0; // not stuck
		}
		else
		{
			// stuck
			setLookAt(m_vMoveTo,PRIORITY_STUCK);

			if ( m_fStuckJumpTime < g_Engine.time )
			{
				m_fStuckJumpTime = g_Engine.time + Math.RandomFloat(1.0f,2.0f);
				Jump();
			}
			// look at waypoint
		}

		DoJump();
	}

	bool IsHoldingMinigun ()
	{
		CBotWeapon@ weap = m_pWeapons.getCurrentWeapon();

		if ( weap !is null )
		{
			if ( weap.IsMinigun() )
			{
				return true;
			}
		}		

		return false;
	}

	bool JumpPending = false;
	float m_fPendingJumpTime = 0.0f;
	
	void Jump ()
	{
		if ( IsHoldingMinigun() ) // we can't jump if we are holding minigun, if we really need to jump then drop it
		{
			// can't jump while holding minigun
			m_pPlayer.DropItem("weapon_minigun");		
		}

		// wait before pressing jump in order to speed up
		m_fPendingJumpTime = g_Engine.time + Math.RandomFloat(0.1f,0.5f);

		//m_flJumpTime = g_Engine.time;
		//PressButton(IN_JUMP);

	}

	void DoJump ()
	{
		if ( m_fPendingJumpTime > 0.0f ) // ready to jump
		{
			// can only jump on ground

				if ( (( (m_pPlayer.pev.flags & FL_ONGROUND) == FL_ONGROUND )&&(m_pPlayer.pev.velocity.Length2D() > (m_pPlayer.pev.maxspeed/16))) || (m_fPendingJumpTime < g_Engine.time) )
				{
					m_fPendingJumpTime = 0.0f;
					PressButton(IN_JUMP);
					m_flJumpTime = g_Engine.time;
				}
			
		}
	}

	CWaypoint@ m_pNextWpt = null;

	/*void te_sprite(Vector pos, string sprite="sprites/zerogxplode.spr", 
	uint8 scale=10, uint8 alpha=200, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
	{
		NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
		m.WriteByte(TE_SPRITE);
		m.WriteCoord(pos.x);
		m.WriteCoord(pos.y);
		m.WriteCoord(pos.z);
		m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
		m.WriteByte(scale);
		m.WriteByte(alpha);
		m.End();
	}*/
/*
void te_playerattachment(CBasePlayer@ target, float vOffset=51.0f, 
	string sprite="sprites/bubble.spr", uint16 life=16, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_PLAYERATTACHMENT);
	m.WriteByte(target.entindex());
	m.WriteCoord(vOffset);
	m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
	m.WriteShort(life);
	m.End();
}
*/

	void PlayerAttachment ( string Sprite, uint16 life = 30 )
	{
		NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
		m.WriteByte(TE_PLAYERATTACHMENT);
		m.WriteByte(m_pPlayer.entindex());
		m.WriteCoord(48.0f);
		m.WriteShort(g_EngineFuncs.ModelIndex(Sprite));
		m.WriteShort(life);
		m.End();
	}

	void ShoutTakeCover ()
	{
		if ( m_fNextShoutTakeCover < g_Engine.time && m_fNextShout < g_Engine.time )
		{
			m_fNextShoutTakeCover = g_Engine.time + Math.RandomFloat( 20.0f, 40.0f );
			m_fNextShout = g_Engine.time + 3.0f;

			PlayerAttachment("sprites/grenade.spr");

			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_BODY, "speech/grenade1.wav", 1, ATTN_NORM ); 
		}
	}

	void ShoutMedic ()
	{
		if ( m_fNextShoutMedic < g_Engine.time && m_fNextShout < g_Engine.time  )
		{
			m_fNextShoutMedic = g_Engine.time + Math.RandomFloat( 20.0f, 40.0f );
			m_fNextShout = g_Engine.time + 3.0f;
			
			PlayerAttachment("sprites/saveme.spr");

			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_BODY, "speech/saveme1.wav", 1, ATTN_NORM ); 
		}
	}

	Vector getAimVector ( CBaseEntity@ pEntity )
	{
		Vector ret;

		int visibleFlags = m_pVisibles.isVisible(pEntity.entindex());

		if ( (visibleFlags & VIS_FL_HEAD) == VIS_FL_HEAD )
			ret = UTIL_EyePosition(pEntity);
		else
			ret = UTIL_EntityOrigin(pEntity);

		CBotWeapon@ pCurrentWeapon = m_pWeapons.getCurrentWeapon();

		if ( pCurrentWeapon !is null )
		{
			if ( pCurrentWeapon.IsRPG() )
			{
				float distance = distanceFrom(pEntity);
				float rocketspeed = 1000;

				float time = distance/rocketspeed;

				ret = ret + (pEntity.pev.velocity*time);
			}
		}

		return ret;
	}

	/**
	 * DoLook()
	 *
	 * look priority will sort everything out
	 **/
	void DoLook ()
	{
		CBaseEntity@ pEnemy = m_pEnemy.GetEntity();

		if ( pEnemy !is null )
		{						
			setLookAt(getAimVector(pEnemy),PRIORITY_ATTACK);


			//BotMessage("LOOKING AT ENEMY!!!\n");
		}
		else if ( IsOnLadder() || (m_pPlayer.pev.waterlevel > 1) )		
		{
			setLookAt(m_vLadderVector,PRIORITY_LADDER);
		}		
		else if ( m_fLastHurt > g_Engine.time )
		{
			setLookAt(m_vHurtOrigin,PRIORITY_HURT);
		}		
		else if ( m_pNextWpt !is null && m_pNextWpt.hasFlags(W_FL_JUMP) )
		{
			setLookAt(m_pNextWpt.m_vOrigin,PRIORITY_WAYPOINT);
		}
		else if ( hasHeardNoise() && (m_pEnemiesVisible.EnemiesVisible() == 0 ) )
		{
			setLookAt(m_vNoiseOrigin,PRIORITY_LISTEN);
		}
		else if ( m_bLastSeeEnemyValid && ((m_fLastSeeEnemyTime+7) > g_Engine.time) )
		{
			setLookAt(m_vLastSeeEnemy,PRIORITY_LAST_SEE_ENEMY);
		}
		else if (m_bMoveToValid )
		{			
			if ( m_pNextWpt !is null )
			{
				int index = m_pNextWpt.iIndex;

				Vector vLookat = m_pNextWpt.m_vOrigin;

				if ( m_fBelief.isValid(index) )
				{
					if ( m_fBelief.isDangerous(index) )
					{
						if ( m_fBelief.isDangerLocationValid(index) )
						{
							vLookat = m_fBelief.DangerLocation(index);
						}
					}
				}

				setLookAt(vLookat,PRIORITY_WAYPOINT);
			}
			else 
			{
				setLookAt(m_vMoveTo,PRIORITY_WAYPOINT);
			}
		}
	}

	void grapple ( Vector vGrapple, Vector vTo )
	{
		// grapple from current position, aim at grapple and head towards 'to'
		if ( m_pCurrentSchedule is null )
			m_pCurrentSchedule = RCBotSchedule();
		
		m_pCurrentSchedule.addTaskFront(CGrappleTask(vGrapple,vTo));			
	}

	void DoButtons ()
	{
		CBotWeapon@ pCurrentWeapon = m_pWeapons.getCurrentWeapon();

		if ( m_pBlocking.GetEntity() !is null )
		{
			CBaseEntity@ pBlocking = m_pBlocking.GetEntity();

			if ( pBlocking.GetClassname() == "func_pushable" )
			{
				PressButton(IN_USE);
			}
			else if ( pBlocking.GetClassname() == "func_breakable" )
			{
				if ( BreakableIsEnemy(pBlocking) )
				{
					m_pEnemy = pBlocking;
				}
			}
		}
		//if ( m_pEnemy.GetEntity() !is null )
		//	BotMessage("ENEMY");

		if ( HealthPercent() < 0.5f )
		{
			ShoutMedic();
		}

		if ( !ceasedFiring() )
		{	
			CBaseEntity@ pEnemy = m_pEnemy.GetEntity();

			if ( pCurrentWeapon !is null && pCurrentWeapon.needToReload(this) )
			{
				if ( pEnemy !is null )
					TakeCover(UTIL_EntityOrigin(pEnemy));
				else if( Math.RandomLong( 0, 100 ) < 99 )
					PressButton(IN_RELOAD);

			}
			else if ( pEnemy !is null && pCurrentWeapon !is null )
			{
				float fDist = distanceFrom(pEnemy);
				CBaseEntity@ enemy = m_pEnemy.GetEntity();
				bool bPressAttack1 = pCurrentWeapon.shouldFire();
				bool bPressAttack2 = Math.RandomLong(0,100) < 25 && pCurrentWeapon.CanUseSecondary() && pCurrentWeapon.secondaryWithinRange(fDist);
			
				CBaseEntity@ groundEntity = g_EntityFuncs.Instance(m_pPlayer.pev.groundentity);		
				Vector entityOrigin = UTIL_EntityOrigin(enemy);

				if ( pCurrentWeapon !is null )
				{
					// I am using a melee weapon and enemy is below me, I need  to crouch to hit it
					if ( pCurrentWeapon.IsMelee() && (groundEntity is m_pEnemy.GetEntity()) || (entityOrigin.z < (m_pPlayer.pev.origin.z - 32)) )
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
			else if ( pEnemy is null && pCurrentWeapon !is null )
			{
				if ( pCurrentWeapon.IsSniperRifle() && pCurrentWeapon.IsZoomed() )
					PressButton(IN_ATTACK2);					
			}
			else if ( pCurrentWeapon !is null )
			{
				if ( pCurrentWeapon.IsRPG() && !pCurrentWeapon.IsZoomed() )
					PressButton(IN_ATTACK2);
			}
		}
	}

	float m_fSuicideTime = 0.0f;

	void suicide ()
	{
		if (m_fSuicideTime < g_Engine.time )
		{
			m_fNextShout = g_Engine.time + 3.0f; // prevents bot from shouting medic
			m_pPlayer.Killed(m_pPlayer.pev, 0);
			m_fSuicideTime = g_Engine.time + 10.0f;
			BotMessage("suicide() " + m_pPlayer.pev.netname + ": tasks: " + m_fNumTasks + ", failed: " + m_fNumTasksFailed);
		}
	}

	void DoTasks ()
	{
		m_iCurrentPriority = PRIORITY_TASK;

		if ( m_fTaskFailTime < g_Engine.time) 
		{
			if ( m_fNumTasksFailed > 0 && m_fNumTasks > 0 )
			{
				if ( m_pBotSuicide.GetBool() == true )
				{
					float m_fFailRate = m_fNumTasksFailed/m_fNumTasks;

					if ( m_fFailRate > 0.9f ) // 90% of tasks have failed 
					{
						suicide(); // kill myself! stuck with no tasks for too long!!!
						return;
					}
				}
			}

			// check again in 30 sec
			m_fTaskFailTime = g_Engine.time + 30;
		}

		if ( !m_bReEvaluateUtility && m_pCurrentSchedule !is null )
		{
			if ( m_pCurrentSchedule.execute(this) == SCHED_TASK_FAIL )
			{
				m_fNumTasksFailed += 1.0f;
				@m_pCurrentSchedule = null;
				//BotMessage("m_pCurrentSchedule.execute(this) == SCHED_TASK_FAIL");
			}
			else if ( m_pCurrentSchedule.numTasksRemaining() == 0 )
			{
				@m_pCurrentSchedule = null;	
				// reset failed count	
				m_fNumTasksFailed = 0;
				//BotMessage("m_pCurrentSchedule.numTasksRemaining() == 0");
			}
		}
		else
		{
			if ( m_pDisableUtil.GetBool() == false )
			{
				m_bReEvaluateUtility = false;
				
				@m_pCurrentSchedule = utils.execute(this);

				if ( @m_pCurrentSchedule != null )
					m_fNumTasks+= 1.0f; // new task
			}
		}

		m_iCurrentPriority = PRIORITY_NONE;
	}
}

BotManager::BaseBot@ CreateRCBot( CBasePlayer@ pPlayer )
{
	return @RCBot( pPlayer );
}


final class BotEnemySeen
{
	EHandle pEnemy;
	//Vector vLastKnown;	

	BotEnemySeen ( CBaseEntity@ pent )
	{
		pEnemy = EHandle(pent);
		//vLastKnown = Vector(0,0,0); // not used atm
	}

	bool isEnemy ( CBaseEntity@ pent )
	{
		return pEnemy.GetEntity() is pent;
	}	

	float getEnemyFactor ( RCBot@ bot )
	{
		CBaseEntity @entity = pEnemy.GetEntity();

		float fFactor = bot.distanceFrom(entity.pev.origin) * entity.pev.size.Length();

		if ( entity.GetClassname() == "func_breakable" )
			fFactor *= 2;
		else if ( entity.GetClassname() == "monster_male_assassin" )
			fFactor /= 2;
		// focus on nearly dead enemies
		fFactor += entity.pev.health;

		return fFactor;
	}

	/*bool LastKnownVisible ()
	{
		return bot.Visible(vLastKnown);
	}*/

}

final class BotEnemyLastSeen
{
	Vector vLastSeen;
	Vector vVelocity;
	Vector vBotLocation;
	EHandle pEnemy;

	BotEnemyLastSeen ( CBaseEntity@ pent, RCBot@ bot )
	{
		pEnemy = EHandle(pent);
		vLastSeen = UTIL_EntityOrigin(pent);
		vBotLocation = bot.m_pPlayer.pev.origin;
		vVelocity = pent.pev.velocity;
	}

	bool IsEntity ( CBaseEntity@ pent )
	{
		return pEnemy.GetEntity() is pent;
	}

	Vector getGrenadePosition ( )
	{
		// don't add velocity 
		return vLastSeen;
	}

	CBaseEntity@ getEntity ()
	{
		return pEnemy.GetEntity();
	}

	// if invalid remove from list
	// if valid use as potential view point
	bool Valid ( RCBot@ bot )
	{
		CBaseEntity@ pent = pEnemy.GetEntity();

		if ( pent is null )
			return false;

		// not dead - valid
		return bot.IsEnemy(pent);
	}	

    // return possible enemy location
	Vector getLocation ()
	{
		return vLastSeen + vVelocity;
	}
}

final class BotEnemyLastSeenList
{
	array<BotEnemyLastSeen@> m_pList;
	uint lastSeenMax = 3;

	BotEnemyLastSeenList ()
	{
		m_pList = {};
	}

	BotEnemyLastSeen@ nearestEnemySeen ( RCBot@ bot )
	{
		// find within 4000 units
		float min_distance = 4000.0;
		BotEnemyLastSeen@ ret = null;

		for ( uint i = 0; i < m_pList.length(); i ++ )
		{
			if ( m_pList[i].Valid(bot) )
			{
				float distance = bot.distanceFrom(m_pList[i].getEntity());

				if ( distance < min_distance )
				{
					min_distance = distance;
					@ret = m_pList[i];
				}
			}
			
		}

		return ret;
	}

	void add ( CBaseEntity@ pent, RCBot@ bot )
	{
		// remove old position
		remove(pent);
		// add new position
		if ( m_pList.length() > lastSeenMax )
		{
			m_pList.removeAt(0);
		}

		m_pList.push_back(BotEnemyLastSeen(pent,bot));
	}

	void remove ( CBaseEntity@ pent )
	{
		// find entity
		for ( uint i = 0; i < m_pList.length(); i ++ )
		{
			if ( m_pList[i].IsEntity(pent) )
			{
				// found
				m_pList.removeAt(i);
				// removed
				return;
			}
		}
	}
}

final class BotEnemiesVisible
{
	array<BotEnemySeen@> enemiesVisible;
	BotEnemyLastSeenList lastSeen;

	uint maxLastSeen = 3;

	void clear ()
	{
		enemiesVisible = {};
	}

	void newEnemy ( CBaseEntity@ pent )
	{
		enemiesVisible.push_back(BotEnemySeen(pent));
	}

	BotEnemyLastSeen@ nearestEnemySeen ( RCBot@ bot )
	{		
		return lastSeen.nearestEnemySeen(bot);
	}

	bool enemyLost ( CBaseEntity@ pent, RCBot@ bot )
	{
		lastSeen.add(pent,bot);

		return removeEnemy(pent);
	}
	// High CPU used here
	float getDanger ( Vector position )
	{
		float ret = 0;

		for ( uint i = 0; i < enemiesVisible.length(); i ++ )
		{
			BotEnemySeen@ temp = @enemiesVisible[i];
			CBaseEntity@ pent = temp.pEnemy.GetEntity();
			float distance = 0;

			if ( pent is null )
			{
				continue;
			}

			distance = (pent.GetOrigin() - position).Length();
			distance = 128.0 - distance;

			if ( distance < 0 )
				distance = 0;

			ret += distance;
		}

		return ret;
	}

	EHandle getBestEnemy ( RCBot@ bot )
	{
		uint i;
		float min_factor = 0.0f;
		EHandle ret = EHandle(null);
		bool none = true;
		array<BotEnemySeen@> toRemove;

		for ( i = 0; i < enemiesVisible.length(); i ++ )
		{
			BotEnemySeen@ temp = @enemiesVisible[i];
			float factor = 0;

			if ( temp.pEnemy.GetEntity() is null )
			{
				toRemove.push_back(temp);
				continue;
			}

			if ( !bot.IsEnemy(temp.pEnemy.GetEntity()) )
			{
				toRemove.push_back(temp);
				continue;
			}

			factor = temp.getEnemyFactor(bot);
//BotMessage("fator = " + factor);	
			if ( none || (factor < min_factor) )
			{			
				none = false;
				min_factor = factor;
				ret = temp.pEnemy;
			} 
		}

		clearIndices(toRemove);

		//if ( ret.GetEntity() !is null )
		//	BotMessage("Best enemy ==  " + ret.GetEntity().pev.classname + "\n");
		//	else 
		//	BotMessage("Best enemy == null :( length == " + enemiesVisible.length() + "  \n");

		return ret;
	}

	int EnemiesVisible ()
	{
		return enemiesVisible.length();
	}

	bool removeEnemy ( CBaseEntity@ pent )
	{
		uint i;
	//	BotMessage("removeEnemy");
		for ( i = 0; i < enemiesVisible.length(); i ++ )
		{
			BotEnemySeen@ temp = enemiesVisible[i];

			if ( temp.isEnemy(pent) )
			{
				enemiesVisible.removeAt(i);					
				return true;
			}
		}

		return false;
	//	BotMessage("removeEnemy FAILED");
	}

	void clearIndices ( array<BotEnemySeen@> to_clear )
	{
		uint i;

		while ( to_clear.length() > 0 )
		{
			BotEnemySeen@ toRemove = to_clear[0];

			for ( i = 0; i < enemiesVisible.length(); i ++ )
			{
				BotEnemySeen@ temp = enemiesVisible[i];

				if ( temp is toRemove )
				{
					enemiesVisible.removeAt(i);
					to_clear.removeAt(0);
					break;
				}
			}
		}
	}

}