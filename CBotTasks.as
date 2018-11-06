
// ------------------------------------
// TASKS / SCHEDULES - 	START
// ------------------------------------
class RCBotTask
{
	bool m_bComplete = false;
	bool m_bFailed = false;
    bool m_bInit = false;

    float m_fTimeout = 0.0f;
    float m_fDefaultTimeout = 30.0f;

    RCBotSchedule@ m_pContainingSchedule;

	void Complete ()
	{
		m_bComplete = true;	
	}

    void setTimeout ( float timeout )
    {
        m_fDefaultTimeout = timeout;
    }

	void Failed ()
	{
		m_bFailed = true;
	}	

    void setSchedule ( RCBotSchedule@ sched )
    {
        @m_pContainingSchedule = sched;
    }

    void init ()
    {
        if ( m_bInit == false )
        {
            m_fTimeout = g_Engine.time + m_fDefaultTimeout;
            m_bInit = true;
        }
        
    }

    string DebugString ()
    {
        return "";
    }

    bool timedOut ()
    {
        return g_Engine.time > m_fTimeout;
    }

    void execute ( RCBot@ bot )
    {
 
    }
}

class RCBotSchedule
{
	array<RCBotTask@> m_pTasks;
    uint m_iCurrentTaskIndex;

    RCBotSchedule()
    {
        m_iCurrentTaskIndex = 0;
    }

	void addTaskFront ( RCBotTask@ pTask )
	{
        pTask.setSchedule(this);
		m_pTasks.insertAt(0,pTask);
	}

	void addTask ( RCBotTask@ pTask )
	{	
        pTask.setSchedule(this);
		m_pTasks.insertLast(pTask);
	}

	bool execute (RCBot@ bot)
	{        
        if ( m_pTasks.length() == 0 )
            return true;

        RCBotTask@ m_pCurrentTask = m_pTasks[0];

        m_pCurrentTask.init();
        m_pCurrentTask.execute(bot);

        if ( m_pCurrentTask.m_bComplete )
        {                
            BotMessage("m_pTasks.removeAt(0)");
            m_pTasks.removeAt(0);
        BotMessage(m_pCurrentTask.DebugString()+" COMPLETE");
            if ( m_pTasks.length() == 0 )
            {
                BotMessage("m_pTasks.length() == 0");
                return true;
            }
        }
        else if ( m_pCurrentTask.timedOut() )
        {
                    BotMessage(m_pCurrentTask.DebugString()+" FAILED");

            m_pCurrentTask.m_bFailed = true;
            // failed
            return true;
        }
        else if ( m_pCurrentTask.m_bFailed )
        {
                    BotMessage(m_pCurrentTask.DebugString()+" FAILED");

            return true;
        }

        return false;
	}
}

// ------------------------------------
// TASKS / SCHEDULES - 	END
// ------------------------------------


final class CFindHealthTask : RCBotTask 
{
    CFindHealthTask ( )
    {

    }
    string DebugString ()
    {
        return "CFindHealthTask";
    }

    void execute ( RCBot@ bot )
    {
        // Search for health to pick up or health dispenser
        CBaseEntity@ pent = null;

        BotMessage("CFindHealthTask");

        @pent = UTIL_FindNearestEntity("func_healthcharger",bot.m_pPlayer.EyePosition(),200.0f,true,false);

        if ( pent !is null )
        {
            BotMessage("func_healthcharger");

            // add task to use health charger
            m_pContainingSchedule.addTask(CUseHealthChargerTask(bot,pent));
            Complete();
            return;                        
        }              

        
        while ( (@pent = g_EntityFuncs.FindEntityByClassname(pent, "item_healthkit")) !is null )
        {
            // within reaching distance
            if ( bot.distanceFrom(pent) < 400 )
            {
                if ( UTIL_IsVisible(bot.m_pPlayer.pev.origin, pent, bot.m_pPlayer ))
                {
                        if ( (pent.pev.effects & EF_NODRAW) != EF_NODRAW )
                        {
                            BotMessage("item_healthkit");
                            // add Task to pick up health
                            m_pContainingSchedule.addTask(CPickupItemTask(bot,pent));
                            Complete();
                            return;
                        }
                }
            }

        }

        
            BotMessage("nothing FOUND");

        Failed();
    }
}

final class CFindAmmoTask : RCBotTask 
{
    CFindAmmoTask ( )
    {

    }
    string DebugString ()
    {
        return "CFindAmmoTask";
    }
    void execute ( RCBot@ bot )
    {
        // Search for health to pick up or health dispenser
        CBaseEntity@ pent = null;

        BotMessage("CFindAmmoTask");

        array<CBaseEntity@> pickup;
        
        while ( (@pent = g_EntityFuncs.FindEntityInSphere(pent, bot.m_pPlayer.pev.origin, 512,"ammo_*", "classname" )) !is null )
        {
            if ( (pent.pev.effects & EF_NODRAW) != EF_NODRAW && pent.pev.owner is null )
            {      
                if ( bot.m_pPlayer.HasNamedPlayerItem(pent.GetClassname()) is null )
                {
                    if ( UTIL_IsVisible(bot.origin(),pent,bot.m_pPlayer) )
                    {
                        pickup.insertLast(pent);                  
                    }
                }
            }						
        }

        if ( pickup.length() > 0 )
        {
            @pent = pickup[Math.RandomLong(0,pickup.length()-1)];

            BotMessage(pent.GetClassname());	

            m_pContainingSchedule.addTask(CPickupItemTask(bot,pent));

            Complete();            
            return;
        }

        Failed();
        return;
    }
}


final class CFindWeaponTask : RCBotTask 
{
    CFindWeaponTask ( )
    {

    }
    string DebugString ()
    {
        return "CFindWeaponTask";
    }
    void execute ( RCBot@ bot )
    {
        // Search for health to pick up or health dispenser
        CBaseEntity@ pent = null;

        array<CBaseEntity@> pickup;

        BotMessage("CFindWeaponTask");        
        
        while ( (@pent = g_EntityFuncs.FindEntityInSphere(pent, bot.m_pPlayer.pev.origin, 512,"weapon_*", "classname" )) !is null )
        {
            if ( (pent.pev.effects & EF_NODRAW) != EF_NODRAW && pent.pev.owner is null )
            {      
                if ( bot.m_pPlayer.HasNamedPlayerItem(pent.GetClassname()) is null )
                {
                    if ( UTIL_IsVisible(bot.origin(),pent,bot.m_pPlayer) )
                    {
                        pickup.insertLast(pent);                  
                    }
                }
            }						
        }

        if ( pickup.length() > 0 )
        {
            @pent = pickup[Math.RandomLong(0,pickup.length()-1)];

            BotMessage(pent.GetClassname());	

            m_pContainingSchedule.addTask(CPickupItemTask(bot,pent));
            
            Complete();            
            return;
        }

        Failed();
        return;
    }
}

final class CFindArmorTask : RCBotTask 
{
    CFindArmorTask ( )
    {

    }
    string DebugString ()
    {
        return "CFindArmorTask";
    }
    void execute ( RCBot@ bot )
    {
        // Search for health to pick up or health dispenser
        CBaseEntity@ pent = null;

        BotMessage("CFindArmorTask");

        @pent = UTIL_FindNearestEntity("func_recharge",bot.m_pPlayer.EyePosition(),200.0f,true,false);

        if ( pent !is null )
        {
                BotMessage("func_recharge");

                // add task to use health charger
                m_pContainingSchedule.addTask(CUseArmorCharger(bot,pent));
                Complete();
                return;                           
        }        
        
        while ( (@pent = g_EntityFuncs.FindEntityByClassname(pent, "item_battery")) !is null )
        {            
            // within reaching distance
            if ( bot.distanceFrom(pent) < 400 )
            {
                if ( UTIL_IsVisible(bot.m_pPlayer.pev.origin, pent, bot.m_pPlayer ))
                {
                        if ( (pent.pev.effects & EF_NODRAW) != EF_NODRAW )
                        {
                            BotMessage("item_battery");
                            // add Task to pick up health
                            m_pContainingSchedule.addTask(CPickupItemTask(bot,pent));
                            Complete();
                            return;
                        }                
                }
            }
            
        }

        BotMessage("nothing FOUND");

        Failed();
    }
}

final class CPickupItemTask : RCBotTask 
{
    CBaseEntity@ m_pItem;
    string DebugString ()
    {
        return "CPickupItemTask";
    }
    CPickupItemTask ( RCBot@ bot, CBaseEntity@ item )
    {
        @m_pItem = item;
    } 

    void execute ( RCBot@ bot )
    {
        BotMessage("CPickupItemTask");

        // can't pick this up!!!
        if ( m_pItem.pev.owner !is null )
            Complete();

        if ( m_pItem.pev.effects & EF_NODRAW == EF_NODRAW )
        {
            BotMessage("EF_NODRAW");
            Complete();
        }

        if ( bot.distanceFrom(m_pItem) > 56 )
        {
            bot.setMove(m_pItem.pev.origin);

             BotMessage("bot.setMove(m_pItem.pev.origin);");
        }
        else
            Complete();
    }
}
/* T O D O
class CUseGrappleTask : RCBotTask
{
    CWaypoint@ m_pWpt;

    enum state
    {
        find_aiming,
        change_weapon,
    }

    CUseGrappleTask ( CWaypoint@ pWpt, CWaypoint@ pNext )
    {

    }

    string DebugString ()
    {
        return "CUseGrappleTask";
    } 

    void execute ( RCBot@ bot )
    {
        StopMoving();
    }
}
*/

final class CFindButtonTask : RCBotTask
{
    CFindButtonTask ( )
    {

    }
    string DebugString ()
    {
        return "CFindButtonTask";
    }
    void execute ( RCBot@ bot )
    {
        //string classname, Vector vOrigin, float fMinDist, bool checkFrame, bool bVisible )
        CBaseEntity@ pent = UTIL_FindNearestEntity("func_button",bot.m_pPlayer.EyePosition(),200.0f,true,false);

        if ( pent !is null )
        {
                        BotMessage("func_button");
                        // add Task to pick up health
                        m_pContainingSchedule.addTask(CUseButtonTask(pent));
                        Complete();
                        return;                                    
        }

        @pent = UTIL_FindNearestEntity("func_rot_button",bot.m_pPlayer.EyePosition(),200.0f,true,false);

        if ( pent !is null )
        {
                        BotMessage("func_rot_button");
                        // add Task to pick up health
                        m_pContainingSchedule.addTask(CUseButtonTask(pent));
                        Complete();
                        return;                                    
        }

        Failed();
    }
}

final class CUseButtonTask : RCBotTask
{
    CBaseEntity@ m_pButton;
    string DebugString ()
    {
        return "CUseButtonTask";
    }
    CUseButtonTask ( CBaseEntity@ button )
    {
        @m_pButton = button;
        m_fDefaultTimeout = 4.0;
    } 

    void execute ( RCBot@ bot )
    {
        Vector vOrigin = UTIL_EntityOrigin(m_pButton);

        if ( m_pButton.pev.frame != 0 )
            Complete();

        bot.setLookAt(vOrigin);

        if ( bot.distanceFrom(m_pButton) > 56 )
        {
            bot.setMove(vOrigin);
            BotMessage("bot.setMove(m_pCharger.pev.origin)");
        }
        else
        {
            bot.StopMoving();

            // within so many degrees of target
           // if ( UTIL_DotProduct(bot.m_pPlayer.pev.v_angle,vOrigin) > 0.7 )    
            {

                BotMessage("bot.PressButton(IN_USE)");

                if ( Math.RandomLong(0,100) < 99 )
                {
                    bot.PressButton(IN_USE);
                    Complete();
                }
            }
        }
    }
}


final class CUseArmorCharger : RCBotTask
{
    CBaseEntity@ m_pCharger;
    string DebugString ()
    {
        return "CUseArmorCharger";
    }
    CUseArmorCharger ( RCBot@ bot, CBaseEntity@ charger )
    {
        @m_pCharger = charger;
        m_fDefaultTimeout = 8.0;
    } 

    void execute ( RCBot@ bot )
    {
        BotMessage("CUseArmorCharger");

        if ( m_pCharger.pev.frame != 0 )
        {
            Complete();
            BotMessage(" m_pCharger.pev.frame == 0");
        }
        if ( bot.m_pPlayer.pev.armorvalue >= 100 )
        {
            Complete();
            BotMessage(" bot.m_pPlayer.pev.armorvalue >= 100");
        }

        Vector vOrigin = UTIL_EntityOrigin(m_pCharger);
 bot.setLookAt(vOrigin);

        if ( bot.distanceFrom(m_pCharger) > 56 )
        {
            bot.setMove(vOrigin);
            BotMessage("bot.setMove(m_pCharger.pev.origin)");
        }
        else
        {
            bot.StopMoving();
           
                        // within so many degrees of target
            //if ( UTIL_DotProduct(bot.m_pPlayer.pev.v_angle,vOrigin) > 0.7 )    
            {
                BotMessage("bot.PressButton(IN_USE)");

                if ( Math.RandomLong(0,100) < 99 )
                {
                    bot.PressButton(IN_USE);
                }
            }
        }
    }  
}

final class CUseHealthChargerTask : RCBotTask
{
    CBaseEntity@ m_pCharger;
    string DebugString ()
    {
        return "CUseHealthChargerTask";
    }
    CUseHealthChargerTask ( RCBot@ bot, CBaseEntity@ charger )
    {
        @m_pCharger = charger;
        m_fDefaultTimeout = 8.0;
    } 

    void execute ( RCBot@ bot )
    {
        if ( m_pCharger.pev.frame != 0 )
            Complete();

        BotMessage("Health  = " + bot.m_pPlayer.pev.health);
        BotMessage("Max Health = " + bot.m_pPlayer.pev.max_health);

        if ( bot.HealthPercent() >= 1.0f )
            Complete();

        Vector vOrigin = UTIL_EntityOrigin(m_pCharger);
        
        bot.setLookAt(vOrigin);

        if ( bot.distanceFrom(m_pCharger) > 64 )
            bot.setMove(vOrigin);
        else
        {
            bot.StopMoving();

            if ( Math.RandomLong(0,100) < 99 )
            {
                bot.PressButton(IN_USE);
            }            
        }
    }  
}

final class CBotButtonTask : RCBotTask 
{
    int m_iButton;
    string DebugString ()
    {
        return "CBotButtonTask";
    }
    CBotButtonTask ( int button )
    {
        m_iButton = button;
    }

    void execute ( RCBot@ bot )
    {
        bot.PressButton(m_iButton);
        Complete();
    }
}

final class CRemoveLastEnemy : RCBotTask
{
    
    string DebugString ()
    {
        return "CRemoveLastEnemy";
    }

    void execute ( RCBot@ bot )
    {
        bot.RemoveLastEnemy();
        Complete();
    }
}

final class CFindPathTask : RCBotTask
{
    RCBotNavigator@ navigator;

    string DebugString ()
    {
        return "CFindPathTask";
    }

    /**
     * @param pEntity - Find moving target
     */ 
    CFindPathTask ( RCBot@ bot, int wpt, CBaseEntity@ pEntity = null )
    {
        @navigator = RCBotNavigator(bot,wpt,pEntity);
    }
/*
    CFindPathTask ( RCBot@ bot, Vector origin )
    {
        @navigator = RCBotNavigator(bot,origin);
    }*/
/*
}
	const int NavigatorState_Complete = 0;
	const int NavigatorState_InProgress = 1;
	const int NavigatorState_Fail = 2;
*/
    void execute ( RCBot@ bot )
    {
        //@bot.navigator = navigator;

        switch ( navigator.run(bot) )
        {
            case NavigatorState_Following:

            navigator.execute(bot);

           // BotMessage("NavigatorState_Following");

            break;
        case NavigatorState_Complete:
 
            // follow waypoint
            BotMessage("NavigatorState_Complete");
        break;
        case NavigatorState_InProgress:
            // waiting...
             BotMessage("NavigatorState_InProgress");
        break;
        case NavigatorState_Fail:
             BotMessage("NavigatorState_Fail");
            Failed();
        break;
        case NavigatorState_ReachedGoal:

            BotMessage("NavigatorState_ReachedGoal");
            Complete();
            break;
        }
    }
}

class CFindPathSchedule : RCBotSchedule
{
    CFindPathSchedule ( RCBot@ bot, int iWpt )
    {
        addTask(CFindPathTask(bot,iWpt));
    }
}


class CBotTaskFindCoverSchedule : RCBotSchedule
{    
    CBotTaskFindCoverSchedule ( RCBot@ bot, CBaseEntity@ hide_from )
    {
        addTask(CBotTaskFindCoverTask(bot,hide_from));
        // reload when arrive at cover point
        addTask(CBotButtonTask(IN_RELOAD));
    }
    
}

class CBotTaskHealPlayer : RCBotTask 
{
    float m_fLastVisibleTime = 0.0f;
    EHandle m_pHeal;

    CBotTaskHealPlayer ( CBaseEntity@ pHeal )
    {
        m_pHeal = pHeal;
        // Allow 15 sec max for task
        setTimeout(15.0f);
    }

     void execute ( RCBot@ bot )
     {
        CBaseEntity@ pent = m_pHeal.GetEntity();
        Vector vHeal;

        if ( pent is null )
            Complete();        

        if (!bot.CanHeal(pent) )
            Complete();        

        // stop bot from attacking enemies whilst healing
        bot.ceaseFire(true);

        vHeal = pent.EyePosition();

        CBotWeapon@ medikit = bot.getMedikit();

        if ( m_fLastVisibleTime == 0.0f )
            m_fLastVisibleTime = g_Engine.time;

        // Look at player
        bot.setLookAt(vHeal);

        if ( !bot.isCurrentWeapon(medikit) )
        {
            bot.selectWeapon(medikit);
            m_fLastVisibleTime = g_Engine.time;
        }
        else
        {
            if ( bot.isEntityVisible(pent) )
            {
                m_fLastVisibleTime = g_Engine.time + 3.0f;
            }
            else 
            {
                // haven't seen the player for three seconds
                if ( m_fLastVisibleTime < g_Engine.time )
                {
                    Failed();
                }
            }

            if ( bot.distanceFrom(vHeal) > 64.0f )
            {
                bot.setMove(vHeal);
            }
            else
            {
                bot.PressButton(IN_ATTACK);
                bot.StopMoving();
            }
        }
     }
}

class CBotHumanTowerTask : RCBotTask
{
    Vector m_vOrigin;

    CBotHumanTowerTask ( Vector vOrigin )
    {
        m_vOrigin = vOrigin;

        setTimeout(15.0f);
    }

     void execute ( RCBot@ bot )
     {
         CBasePlayer@ groundPlayer = UTIL_FindNearestPlayer(m_vOrigin,128,bot.m_pPlayer,true);

        bot.setMoveSpeed(bot.m_pPlayer.pev.maxspeed/2);

         if ( groundPlayer !is null )
         {
            Vector vPlayer = UTIL_EntityOrigin(groundPlayer);

            

            if ( UTIL_yawAngleFromEdict(vPlayer,bot.m_pPlayer.pev.v_angle,bot.m_pPlayer.pev.origin) < 15 )    
                bot.setMove(vPlayer);

            bot.setLookAt(vPlayer);

            if ( bot.m_pPlayer.pev.groundentity is groundPlayer.edict() )
                {
                    bot.StopMoving();

                    Complete();
                }

            else if ( bot.distanceFrom(groundPlayer) < 96 )
            {
                if ( Math.RandomLong(0,100) > 50 )
                    bot.PressButton(IN_JUMP);
            }
         }
         else
         {

            if ( bot.distanceFrom(m_vOrigin) > 96 )
            {
                bot.setMove(m_vOrigin);

                BotMessage("bot.distanceFrom(m_vOrigin) > 96");
            }
            else 
            {
                CBaseEntity@ playerOnTop = UTIL_FindNearestPlayerOnTop(bot.m_pPlayer);

                if ( playerOnTop !is null  )
                {
                    BotMessage("playerOnTop !is null");

                    // stand up 
                    // look at player
                    bot.setLookAt(UTIL_EntityOrigin(playerOnTop));
                }
                else 
                {
                    bot.PressButton(IN_DUCK);
                }

                bot.StopMoving();
            }
         }
     }
}

class CBotTaskFindCoverTask : RCBotTask
{    
    RCBotCoverWaypointFinder@ finder;
    string DebugString ()
    {
        return "CBotTaskFindCoverTask";
    }
    CBotTaskFindCoverTask ( RCBot@ bot, CBaseEntity@ hide_from )
    {
        @finder = RCBotCoverWaypointFinder(g_Waypoints.m_VisibilityTable,bot,hide_from);    

        if ( finder.state == NavigatorState_Fail )
        {
            BotMessage("FINDING COVER FAILED!!!");
            Failed();
        }
    }


     void execute ( RCBot@ bot )
     {
         if ( finder.execute() )
         {
             m_pContainingSchedule.addTask(CFindPathTask(bot,finder.m_iGoalWaypoint));
             BotMessage("FINDING COVER COMPLETE!!!");
             Complete();
         }
         else
            Failed();
     }
}


/// UTIL

abstract class CBotUtil
{
    float utility;
    float m_fNextDo;

    CBotUtil ( ) 
    { 
        utility = 0; 
        m_fNextDo = 0.0;   
    }

    void reset ()
    {
        m_fNextDo = 0.0;
    }

    bool canDo (RCBot@ bot)
    {
        return g_Engine.time > m_fNextDo;
    }

    void setNextDo ()
    {
        m_fNextDo = g_Engine.time + 30.0f;
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        return null;
    }

    float calculateUtility ( RCBot@ bot )
    {
        return 0;
    }    

    void setUtility ( float util )
    {
        utility = util;
    }
}

/**
 * CBotHealPlayerUtil
 *
 * Utility function for healing a living player with medikit
 */
class CBotHealPlayerUtil : CBotUtil
{
    float calculateUtility ( RCBot@ bot )
    {        
        return 1.0f;
    }

    bool canDo (RCBot@ bot)
    {
        return (g_Engine.time > m_fNextDo) && bot.m_pHeal.GetEntity() !is null && bot.CanHeal(bot.m_pHeal.GetEntity());
    }    

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        CBaseEntity@ pHeal = bot.m_pHeal.GetEntity();

        if ( pHeal is null )
            return null;

        // Vector vecLocation, CBasePlayer@ player = null, int iIgnore = -1, float minDistance = 512.0f, bool bCheckVisible = true, bool bIgnoreUnreachable = true )
        int iWpt = g_Waypoints.getNearestWaypointIndex(pHeal.EyePosition(),pHeal,-1,400.0f,true,false); 

        if ( iWpt != -1 )
        {
            RCBotSchedule@ sched = RCBotSchedule();

            //RCBot@ bot, int wpt, CBaseEntity@ pEntity = nul
            sched.addTask(CFindPathTask(bot,iWpt,pHeal));
            sched.addTask(CBotTaskHealPlayer(pHeal));

            return sched;
        }

        return null;
    }
}


class CBotGetHealthUtil : CBotUtil
{

    float calculateUtility ( RCBot@ bot )
    {
        float healthPercent = float(bot.m_pPlayer.pev.health) / bot.m_pPlayer.pev.max_health;
     
        return (1.0f - healthPercent);
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer,W_FL_HEALTH);				

        if ( iWpt != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iWpt);

            sched.addTask(CFindHealthTask());

            return sched;
        }

        return null;
    }
}

class CBotGetWeapon : CBotUtil
{

   float calculateUtility ( RCBot@ bot )
    {
        // TO DO calculate on bots current weapons collection
        float ret = 1.0 - bot.m_pWeapons.getNumWeaponsPercent(bot);
        BotMessage("CBotGetWeapon UTILILTY = " + ret);
        return ret;
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer,W_FL_WEAPON);				

        if ( iWpt != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iWpt);
            sched.addTask(CFindWeaponTask());
            return sched;
        }

        return null;
    }    
}

class CBotGetAmmo : CBotUtil
{

   float calculateUtility ( RCBot@ bot )
    {
        float ret = 1.0 - bot.m_pWeapons.getPrimaryAmmoPercent(bot);
        BotMessage("CBotGetAmmo UTILILTY = " + ret);
        return ret;
        // TO DO Calculate based on bots current weapon / ammo inventory
        //return 0.45;
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer,W_FL_AMMO);				

        if ( iWpt != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iWpt);
            sched.addTask(CFindAmmoTask());
            return sched;
        }

        return null;
    }    
}

class CBotGetArmorUtil : CBotUtil
{
    
   float calculateUtility ( RCBot@ bot )
    {
        float healthPercent = float(bot.m_pPlayer.pev.armorvalue) / 100;

        return (1.0f - healthPercent);
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer,W_FL_ARMOR);				

        if ( iWpt != -1 )
        {
             RCBotSchedule@ sched = CFindPathSchedule(bot,iWpt);

             sched.addTask(CFindArmorTask());   

             return sched;
        }
        return null;
    }    
}

class CBotGotoObjectiveUtil : CBotUtil
{
    CFailedWaypointsList failed;

    float calculateUtility ( RCBot@ bot )
    {
        return 0.2;
    }

    void reset ()
    {
        failed.clear();
        m_fNextDo = 0;
    }

    void setNextDo ()
    {
        m_fNextDo = g_Engine.time + 1.0f;
    }   

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iRandomGoal = g_Waypoints.getRandomFlaggedWaypoint(W_FL_IMPORTANT,failed);

        if ( iRandomGoal != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iRandomGoal);

            sched.addTask(CFindButtonTask());

            failed.add(iRandomGoal);

            return sched;
        }
        else
            failed.clear();

        return null;
    }
}

class CBotFindLastEnemyUtil : CBotUtil
{
    float calculateUtility ( RCBot@ bot )
    {        
            return bot.totalHealth(); 
    }

    bool canDo (RCBot@ bot)
    {
        if ( bot.m_pEnemy.GetEntity() is null && bot.m_bLastSeeEnemyValid && bot.m_pLastEnemy.GetEntity() !is null )
            return CBotUtil::canDo(bot);

        return false;
    }    

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iRandomGoal = g_Waypoints.getNearestWaypointIndex(bot.m_vLastSeeEnemy);

        if ( iRandomGoal != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iRandomGoal);

            sched.addTask(CRemoveLastEnemy());

            return sched;
        }

        return null;
    }
}



class CBotGotoEndLevelUtil : CBotUtil
{
    CFailedWaypointsList failed;
    
    void reset ()
    {
        failed.clear();
        m_fNextDo = 0;
    }

    float calculateUtility ( RCBot@ bot )
    {
        return 0.3;
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iRandomGoal = g_Waypoints.getRandomFlaggedWaypoint(W_FL_ENDLEVEL,failed);    

        if ( iRandomGoal != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iRandomGoal);

            sched.addTask(CFindButtonTask());

            failed.add(iRandomGoal);

            return sched;
        }
        else
            failed.clear();

        return null;
    }
}

class CBotRoamUtil : CBotUtil
{
    float calculateUtility ( RCBot@ bot )
    {
        return (0.01);
    }

    void setNextDo ()
    {
        m_fNextDo = g_Engine.time + 1.0f;
    }    

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        if ( g_Waypoints.m_iNumWaypoints == 0 )
            return null;

        int iRandomGoal = Math.RandomLong(0,g_Waypoints.m_iNumWaypoints-1);

        CWaypoint@ pWpt = g_Waypoints.getWaypointAtIndex(iRandomGoal);

        if ( pWpt.hasFlags(W_FL_DELETED) )
            return null;

        if ( pWpt.hasFlags(W_FL_UNREACHABLE) )
            return null;
            
        return CFindPathSchedule(bot,iRandomGoal);
    }
}

class CBotUtilities 
{
    array <CBotUtil@>  m_Utils;

    CBotUtilities ( RCBot@ bot )
    {
            m_Utils.insertLast(CBotGetHealthUtil());
            m_Utils.insertLast(CBotGetArmorUtil());
            m_Utils.insertLast(CBotGotoObjectiveUtil());
            m_Utils.insertLast(CBotGotoEndLevelUtil());
            m_Utils.insertLast(CBotGetAmmo());
            m_Utils.insertLast(CBotGetWeapon());
            m_Utils.insertLast(CBotFindLastEnemyUtil());
            m_Utils.insertLast(CBotRoamUtil());
            m_Utils.insertLast(CBotHealPlayerUtil());
    }

    void reset ()
    {
        for ( uint i = 0; i < m_Utils.length(); i ++ )
        {
             m_Utils[i].reset();            
        }
    }

    RCBotSchedule@  execute ( RCBot@ bot )
    {
        array <CBotUtil@>  UtilsCanDo;

        for ( uint i = 0; i < m_Utils.length(); i ++ )
        {
            if ( m_Utils[i].canDo(bot) )
            {
                   
                m_Utils[i].setUtility(m_Utils[i].calculateUtility(bot));
                BotMessage("Utility = " + m_Utils[i].utility);
                UtilsCanDo.insertLast(m_Utils[i]);
            }
        }

        if ( UtilsCanDo.length() > 0 )
        {
            UtilsCanDo.sort(function(a,b) { return a.utility > b.utility; });

            for ( uint i = 0; i < UtilsCanDo.length(); i ++ )
            {
                RCBotSchedule@ sched = UtilsCanDo[i].execute(bot);

                if ( sched !is null )
                {
                    
                    UtilsCanDo[i].setNextDo();
                    return sched;
                }
            }
        }
        else
            reset();

        return null;
    }
}