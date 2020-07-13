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
const int PRIORITY_TASK = 3;
const int PRIORITY_HURT = 4;
const int PRIORITY_ATTACK = 5;
const int PRIORITY_LADDER = 6;
const int PRIORITY_OVERRIDE = 7;

// ------------------------------------
// BOT BASE - START
// ------------------------------------
final class RCBot : BotManager::BaseBot
{	
	//private float m_fNextThink = 0;

	RCBotSchedule@ m_pCurrentSchedule;

	float m_fNextShoutMedic;

	bool init;

	EHandle m_pEnemy;

//	EHandle m_pNextEnemy;

	BotEnemiesVisible m_pEnemiesVisible;

	CBotVisibles@ m_pVisibles;

	CBotUtilities@ utils;

	CBotWeapons@ m_pWeapons;

	EHandle m_pNearestTank;

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

		NetworkMessage m(MSG_ONE, NetworkMessages::NetworkMessageType(9), pPlayer.edict());
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

		if ( szClassname == "func_tank")
			return false;

		if ( entity.pev.deadflag != DEAD_NO )
			return false;

		if ( entity.pev.health <= 0 )
			return false;

		switch ( entity.Classify() )
		{
case 	CLASS_FORCE_NONE	:
case 	CLASS_PLAYER_ALLY	:
case 	CLASS_NONE	:
case 	CLASS_PLAYER	:
case 	CLASS_HUMAN_PASSIVE	:
case 	CLASS_ALIEN_PASSIVE	:
case 	CLASS_INSECT	:
case 	CLASS_PLAYER_BIOWEAPON	:
case 	CLASS_ALIEN_BIOWEAPON	:

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
case 	CLASS_MACHINE	:
case 	CLASS_HUMAN_MILITARY	:
case 	CLASS_ALIEN_MILITARY	:
case 	CLASS_ALIEN_MONSTER	:
case 	CLASS_ALIEN_PREY	:
case 	CLASS_ALIEN_PREDATOR	:
case 	CLASS_XRACE_PITDRONE	:
case 	CLASS_XRACE_SHOCK	:
case 	CLASS_BARNACLE	:

		if ( szClassname == "monster_tentacle" ) // tentacle things dont die
			return false;

		if ( szClassname == "monster_turret" || szClassname == "monster_miniturret" )
		{
			// turret is invincible
			if ( entity.pev.sequence == 0 )
				return false;
		}
/*
		if ( szClassname == "monster_generic" )
			return false;
		 else if ( szClassname,"monster_furniture") )
			return FALSE;
		else if ( FStrEq(szClassname,"monster_leech") )
			return FALSE;
		else if ( FStrEq(szClassname,"monster_cockroach") )
			return FALSE;		*/

		return !entity.IsPlayerAlly();

		default:
		break;
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
			// Wait No player wapoint or a ladder waypoint and not on ladder
			else if( pNextWpt.hasFlags(W_FL_WAIT_NO_PLAYER) || 
			((pNextWpt.hasFlags(W_FL_LADDER))&&(!IsOnLadder())) )
			{
				if ( m_pCurrentSchedule is null )
					m_pCurrentSchedule = RCBotSchedule();
				
				m_pCurrentSchedule.addTaskFront(CBotTaskWaitNoPlayer(pNextWpt.m_vOrigin));
			}			
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
			Jump();
		}
		

		if( wpt.hasFlags(W_FL_HUMAN_TOWER) )
		{
			addToSchedule(CBotHumanTowerTask(wpt.m_vOrigin));
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
		if ( flags & W_FL_PLATFORM == W_FL_PLATFORM )
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

		if ( flags & W_FL_CROUCH == W_FL_CROUCH )
			PressButton(IN_DUCK);

		if ( IsOnLadder() || ((flags & W_FL_LADDER) == W_FL_LADDER) )
		{
			UTIL_DebugMsg(m_pPlayer,"IN_FORWARD",DEBUG_NAV);
			setLookAt(vOrigin);
			PressButton(IN_FORWARD);
		}

		if ( flags & W_FL_STAY_NEAR == W_FL_STAY_NEAR )
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
	void pressButton ( CBaseEntity@ pButton, int iLastWpt )
	{
		//CFindPathTask ( RCBot@ bot, int wpt, CBaseEntity@ pEntity = null )
		int iWpt = g_Waypoints.getNearestWaypointIndex(UTIL_EntityOrigin(pButton),pButton);
		
		if ( iWpt == -1 )
		{
			UTIL_DebugMsg(m_pPlayer,"pressButton() NO PATH",DEBUG_THINK);
			return;
		}

		// don't overflow tasks
		if ( m_pCurrentSchedule.numTasksRemaining() < 5 )
		{
			// This will be the third task
			m_pCurrentSchedule.addTaskFront(CFindPathTask(this,iLastWpt));
			// This will be the second task
			m_pCurrentSchedule.addTaskFront(CUseButtonTask(pButton));
			// This will be the first task
			m_pCurrentSchedule.addTaskFront(CFindPathTask(this,iWpt,pButton));
			

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

	
		if ( entity.pev.flags & FL_MONSTER == FL_MONSTER )
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
			if ( entity.pev.flags & FL_CLIENT != FL_CLIENT )	
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

		if ( entity.pev.flags & FL_MONSTER == FL_MONSTER )
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
			if ( entity.pev.flags & FL_CLIENT != FL_CLIENT )	
				return false;
		}

		if ( entity.pev.flags & FL_GODMODE == FL_GODMODE )
			return false;
// probably a spectator
		if ( entity.pev.effects & EF_NODRAW == EF_NODRAW )
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
	

	void TakeCover ( Vector vOrigin )
	{
		if ( m_fNextTakeCover < g_Engine.time )
		{
			@m_pCurrentSchedule = CBotTaskFindCoverSchedule(this,vOrigin);
			m_fNextTakeCover = g_Engine.time + 8.0;
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

		m_iCurrentPriority = PRIORITY_NONE;
		m_pWeapons.updateWeapons(this);

		ReleaseButtons();

		m_fDesiredMoveSpeed = m_pPlayer.pev.maxspeed;

		BotManager::BaseBot::Think();
		
		//If the bot is dead and can be respawned, send a button press
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
		DoTasks();
		DoVisibles();

		DoListen();

		DoMove();
		DoLook();

		DoWeapons();
		DoButtons();

		
		
	}

	EHandle m_pBlocking = null;

	void setBlockingEntity ( CBaseEntity@ blockingEntity )
	{
		m_pBlocking = blockingEntity;
	}

	void DoWeapons ()
	{	
		if ( !ceasedFiring() )
			m_pWeapons.DoWeapons(this,m_pEnemy);
	}

	/** Smaller factors are better */
	float getEnemyFactor ( CBaseEntity@ entity )
	{
		float fFactor = distanceFrom(entity.pev.origin) * entity.pev.size.Length();

		if ( entity.GetClassname() == "func_breakable" )
			fFactor *= 2;
		else if ( entity.GetClassname() == "monster_male_assassin" )
			fFactor /= 2;
		// focus on nearly dead enemies
		fFactor += entity.pev.health;

		return fFactor;
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
			//BotMessage("CanHeal == TRUE");
			if ( m_pHeal.GetEntity() is null )
				m_pHeal = ent;
			else if ( getHealFactor(ent) < getHealFactor(m_pHeal) )
				m_pHeal = ent;
		}		
		else if ( CanRevive(ent) )
		{
			//BotMessage("CanRevive == TRUE");

			if ( m_pRevive.GetEntity() is null )
				m_pRevive = ent;
			else if ( getHealFactor(ent) < getHealFactor(m_pRevive) )
				m_pRevive = ent;
		}


		//BotMessage("New Visible " + ent.pev.classname + "\n");

		if ( IsEnemy(ent) )
		{
			m_pEnemiesVisible.newEnemy(ent);

			//BotMessage("NEW ENEMY !!!  " + ent.pev.classname + "\n");
			m_fLastSeeEnemyTime = g_Engine.time;
		}

		if ( ent.GetClassname() == "func_tank" )
		{
			if ( UTIL_CanUseTank(m_pPlayer,ent) )
			{
				setNearestTank(ent);
			}
		}

		if ( ent.GetClassname() == "monster_scientist" )
		{
			CBaseEntity@ pScientist = m_pLastSeenScientist.GetEntity();

			if ( ent.IsPlayerAlly() )
			{
				if ( (pScientist is null) || (distanceFrom(ent) < distanceFrom(pScientist)) )
				{
					m_pLastSeenScientist = ent;
				}
			}
		}

		if ( ent.GetClassname() == "monster_barney" || ent.GetClassname() == "monster_otis" )
		{
			CBaseEntity@ pBarney = m_pLastSeenBarney.GetEntity();

			if ( ent.IsPlayerAlly() )
			{
				if ( (pBarney is null) || (distanceFrom(ent) < distanceFrom(pBarney)) )
				{
					m_pLastSeenBarney = ent;
				}
			}
		}	
	}

	void lostVisible ( CBaseEntity@ ent )
	{
		//BotMessage("lost visible\n");


		m_pEnemiesVisible.enemyLost(ent,this);

		if ( m_pHeal.GetEntity() is ent )
		{
			m_pHeal = null;
		}

		if ( m_pRevive.GetEntity() is ent )
		{
			m_pRevive = null;
		}

		if ( m_pNearestTank.GetEntity() is ent )
		{
			m_pNearestTank = null;
		}
	}

	void failedPath ( bool failed )
	{
		m_bLastPathFailed = failed;
	}

	void SpawnInit ()
	{
		if ( init == true )
			return;

			@m_pNextWpt = null;

		m_pEnemiesVisible.clear();
		m_flJumpPlatformTime = 0;
		@m_pExpectedPlatform = null;
		m_iLastWaypointFrom = -1;
		m_iLastWaypointTo = -1;

		m_flJumpTime = 0.0f;

		m_fNextShoutMedic = 0.0f;

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

	bool CanAvoid ( CBaseEntity@ ent )
	{
		if ( IsOnLadder() )
			return false;
		if ( distanceFrom(ent) > 200 )
			return false;
		if ( ent == m_pPlayer )
			return false;
		if ( m_pEnemy.GetEntity() is ent )
		{
			CBotWeapon@ pCurrentWeapon = m_pWeapons.getCurrentWeapon();

			if ( pCurrentWeapon !is null )
			{
				if ( pCurrentWeapon.IsMelee() )
					return false;
			}
		}			
		if ( ent.pev.flags & FL_CLIENT == FL_CLIENT )
			return true;
		if ( ent.pev.flags & FL_MONSTER == FL_MONSTER )
			return true;

		return false;		
	}

	void DoVisibles ()
	{
		// update visible objects
		m_pVisibles.update();
		m_pEnemy = m_pEnemiesVisible.getBestEnemy(this);

		BotEnemyLastSeen@ nearestLastSeen = m_pEnemiesVisible.nearestEnemySeen(this);

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
		//if ( navigator !is null )
		//	navigator.execute(this);
		float fStuckSpeed = 0.1*m_fDesiredMoveSpeed;

		if ( IsOnLadder() || ((m_pPlayer.pev.flags & FL_DUCKING) == FL_DUCKING) )
			fStuckSpeed /= 2;
		else if ( m_pPlayer.pev.waterlevel > 1 )
			fStuckSpeed /= 2;		
		// Can go even slower with minigun
		else if ( IsHoldingMinigun() )
			fStuckSpeed /= 3;

		// for courch jump
		if ( m_flJumpTime + 0.5f > g_Engine.time )
		{
			if ( !IsOnLadder() )
				PressButton(IN_DUCK);
		}

		if (  !m_bMoveToValid || (m_pPlayer.pev.velocity.Length() > fStuckSpeed) )
		{

			if ( m_flStuckTime == 0 )
				m_fStuckJumpTime = Math.RandomFloat(1.0f,4.0f);

			m_flStuckTime = g_Engine.time;

		}
		// stuck for more than 3 sec
		else if ( (m_flStuckTime > 0) && (g_Engine.time - m_flStuckTime) > m_fStuckJumpTime )
		{
			Jump();
			m_flStuckTime = 0;
			
			// reset last enemy could cause lok issues
			m_pLastEnemy = null;
			m_bLastSeeEnemyValid = false;
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
		if ( IsHoldingMinigun() )
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
		if ( m_fPendingJumpTime > 0.0f )
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
			if ( m_pVisibles.isVisible(pEnemy.entindex()) & VIS_FL_HEAD == VIS_FL_HEAD )
				setLookAt(UTIL_EyePosition(pEnemy),PRIORITY_ATTACK);
			else
				setLookAt(UTIL_EntityOrigin(pEnemy),PRIORITY_ATTACK);

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
		else if ( hasHeardNoise() && (m_pEnemiesVisible.EnemiesVisible() == 0 ) )
		{
			setLookAt(m_vNoiseOrigin,PRIORITY_LISTEN);
		}
		else if ( m_bLastSeeEnemyValid && ((m_fLastSeeEnemyTime+5) > g_Engine.time) )
		{
			setLookAt(m_vLastSeeEnemy,PRIORITY_WAYPOINT);
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

		if ( (m_fNextShoutMedic < g_Engine.time) && (HealthPercent() < 0.5f) )
		{
			ClientCommand("medic");
			m_fNextShoutMedic = g_Engine.time + 30.0f;
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

				bool bPressAttack1 = pCurrentWeapon.shouldFire();
				bool bPressAttack2 = Math.RandomLong(0,100) < 25 && pCurrentWeapon.CanUseSecondary() && pCurrentWeapon.secondaryWithinRange(fDist);
			
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

	void DoTasks ()
	{
		m_iCurrentPriority = PRIORITY_TASK;

		if ( m_pCurrentSchedule !is null )
		{
			if ( m_pCurrentSchedule.execute(this) == SCHED_TASK_FAIL )
			{
				@m_pCurrentSchedule = null;
				//BotMessage("m_pCurrentSchedule.execute(this) == SCHED_TASK_FAIL");
			}
			else if ( m_pCurrentSchedule.numTasksRemaining() == 0 )
			{
				@m_pCurrentSchedule = null;			
				//BotMessage("m_pCurrentSchedule.numTasksRemaining() == 0");
			}
		}
		else
		{
			if ( m_pDisableUtil.GetBool() == false )
			{
				@m_pCurrentSchedule = utils.execute(this);
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

	void enemyLost ( CBaseEntity@ pent, RCBot@ bot )
	{
		removeEnemy(pent);

		lastSeen.add(pent,bot);
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

	void removeEnemy ( CBaseEntity@ pent )
	{
		uint i;
	//	BotMessage("removeEnemy");
		for ( i = 0; i < enemiesVisible.length(); i ++ )
		{
			BotEnemySeen@ temp = enemiesVisible[i];

			if ( temp.isEnemy(pent) )
			{
				enemiesVisible.removeAt(i);					
				return;
			}
		}
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