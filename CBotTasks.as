
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

const int SCHED_TASKS_MAX = 16;

const int SCHED_TASK_OK = 0;
const int SCHED_TASK_FAIL = 1;

class RCBotSchedule
{
	array<RCBotTask@> m_pTasks;
    uint m_iCurrentTaskIndex;

    RCBotSchedule()
    {
        m_iCurrentTaskIndex = 0;
    }

    uint numTasksRemaining ()
    {
        return m_pTasks.length();
    }

	void addTaskFront ( RCBotTask@ pTask )
	{
        if ( m_pTasks.length() < SCHED_TASKS_MAX )
        {
            pTask.setSchedule(this);
            m_pTasks.insertAt(0,pTask);
        }
	}

	void addTask ( RCBotTask@ pTask )
	{	
        if ( m_pTasks.length() < SCHED_TASKS_MAX )
        {
            pTask.setSchedule(this);
		    m_pTasks.insertLast(pTask);
        }
	}

	int execute (RCBot@ bot)
	{        
        if ( m_pTasks.length() == 0 )
            return SCHED_TASK_OK;

        RCBotTask@ m_pCurrentTask = m_pTasks[0];

        m_pCurrentTask.init();
        m_pCurrentTask.execute(bot);

        if ( m_pCurrentTask.m_bComplete )
        {                
            m_pTasks.removeAt(0);
            UTIL_DebugMsg(bot.m_pPlayer,m_pCurrentTask.DebugString()+" COMPLETE",DEBUG_TASK);
       
            if ( m_pTasks.length() == 0 )
            {
                UTIL_DebugMsg(bot.m_pPlayer,"m_pTasks.length() == 0",DEBUG_TASK);
             
                return SCHED_TASK_OK;
            }
        }
        else if ( m_pCurrentTask.timedOut() )
        {
            UTIL_DebugMsg(bot.m_pPlayer,m_pCurrentTask.DebugString()+" FAILED",DEBUG_TASK);

            m_pCurrentTask.m_bFailed = true;
            // failed
            return SCHED_TASK_FAIL;
        }
        else if ( m_pCurrentTask.m_bFailed )
        {
            UTIL_DebugMsg(bot.m_pPlayer,m_pCurrentTask.DebugString()+" FAILED",DEBUG_NAV);

            return SCHED_TASK_FAIL;
        }

        return SCHED_TASK_OK;
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

        UTIL_DebugMsg(bot.m_pPlayer,"CFindHealthTask",DEBUG_TASK);

        @pent = UTIL_FindNearestEntity("func_healthcharger",bot.m_pPlayer.EyePosition(),200.0f,true,false);

        if ( pent !is null )
        {
            UTIL_DebugMsg(bot.m_pPlayer,"func_healthcharger",DEBUG_TASK);

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
                            UTIL_DebugMsg(bot.m_pPlayer,"item_healthkit",DEBUG_TASK);
                            // add Task to pick up health
                            m_pContainingSchedule.addTask(CPickupItemTask(bot,pent));
                            Complete();
                            return;
                        }
                }
            }

        }

        
            UTIL_DebugMsg(bot.m_pPlayer,"nothing FOUND",DEBUG_TASK);

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

        UTIL_DebugMsg(bot.m_pPlayer,"CFindAmmoTask",DEBUG_TASK);

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

            UTIL_DebugMsg(bot.m_pPlayer,pent.GetClassname());	

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

        UTIL_DebugMsg(bot.m_pPlayer,"CFindWeaponTask",DEBUG_TASK);        
        
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

            UTIL_DebugMsg(bot.m_pPlayer,pent.GetClassname());	

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

        UTIL_DebugMsg(bot.m_pPlayer,"CFindArmorTask",DEBUG_TASK);

        @pent = UTIL_FindNearestEntity("func_recharge",bot.m_pPlayer.EyePosition(),200.0f,true,false);

        if ( pent !is null )
        {
                UTIL_DebugMsg(bot.m_pPlayer,"func_recharge",DEBUG_TASK);

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
                            UTIL_DebugMsg(bot.m_pPlayer,"item_battery",DEBUG_TASK);
                            // add Task to pick up health
                            m_pContainingSchedule.addTask(CPickupItemTask(bot,pent));
                            Complete();
                            return;
                        }                
                }
            }
            
        }

        UTIL_DebugMsg(bot.m_pPlayer,"nothing FOUND",DEBUG_TASK);

        Failed();
    }
}

final class CPickupItemTask : RCBotTask 
{
    EHandle m_pItem;
    string DebugString ()
    {
        return "CPickupItemTask";
    }
    CPickupItemTask ( RCBot@ bot, CBaseEntity@ item )
    {
        m_pItem = item;

        // five sec to pick up
        m_fDefaultTimeout = 5.0f;
    } 

    void execute ( RCBot@ bot )
    {
        CBaseEntity@ pItem = m_pItem.GetEntity();

        if ( pItem !is null )
            Complete();

        UTIL_DebugMsg(bot.m_pPlayer,"CPickupItemTask",DEBUG_TASK);

        // can't pick this up!!!
        if ( pItem.pev.owner !is null )
            Complete();

        if ( pItem.pev.effects & EF_NODRAW == EF_NODRAW )
        {
            UTIL_DebugMsg(bot.m_pPlayer,"EF_NODRAW",DEBUG_TASK);
            Complete();
        }

        if ( bot.distanceFrom(pItem) > 56 )
        {
            bot.setMove(pItem.pev.origin);

             UTIL_DebugMsg(bot.m_pPlayer,"bot.setMove(m_pItem.pev.origin);",DEBUG_TASK);
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
                        UTIL_DebugMsg(bot.m_pPlayer,"func_button",DEBUG_TASK);
                        // add Task to pick up health
                        m_pContainingSchedule.addTask(CUseButtonTask(pent));
                        Complete();
                        return;                                    
        }

        @pent = UTIL_FindNearestEntity("func_rot_button",bot.m_pPlayer.EyePosition(),200.0f,true,false);

        if ( pent !is null )
        {
                        UTIL_DebugMsg(bot.m_pPlayer,"func_rot_button",DEBUG_TASK);
                        // add Task to pick up health
                        m_pContainingSchedule.addTask(CUseButtonTask(pent));
                        Complete();
                        return;                                    
        }

         @pent = UTIL_FindNearestEntity("trigger_once",bot.m_pPlayer.EyePosition(),200.0f,true,false);

        if ( pent !is null )
        {
                        UTIL_DebugMsg(bot.m_pPlayer,"trigger_once",DEBUG_TASK);
                        // add Task to pick up health
                        m_pContainingSchedule.addTask(CBotMoveToOrigin(UTIL_EntityOrigin(pent)));
                        Complete();
                        return;                                    
        }

         @pent = UTIL_FindNearestEntity("momentary_rot_button",bot.m_pPlayer.EyePosition(),200.0f,true,false);

        if ( pent !is null )
        {
                        UTIL_DebugMsg(bot.m_pPlayer,"momentary_rot_button",DEBUG_TASK);
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

        bot.setLookAt(vOrigin,PRIORITY_TASK);

        if ( bot.distanceFrom(m_pButton) > 64 )
        {
            bot.setMove(vOrigin);
            UTIL_DebugMsg(bot.m_pPlayer,"bot.setMove(m_pCharger.pev.origin)",DEBUG_TASK);
        }
        else
        {
            bot.StopMoving();

            UTIL_DebugMsg(bot.m_pPlayer,"bot.PressButton(IN_USE)",DEBUG_TASK);

            if ( Math.RandomLong(0,100) < 99 )
            {
                bot.PressButton(IN_USE);
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
        UTIL_DebugMsg(bot.m_pPlayer,"CUseArmorCharger",DEBUG_TASK);

        if ( m_pCharger.pev.frame != 0 )
        {
            Complete();
            UTIL_DebugMsg(bot.m_pPlayer," m_pCharger.pev.frame == 0",DEBUG_TASK);
        }
        if ( bot.m_pPlayer.pev.armorvalue >= 100 )
        {
            Complete();
            UTIL_DebugMsg(bot.m_pPlayer," bot.m_pPlayer.pev.armorvalue >= 100",DEBUG_TASK);
        }

        Vector vOrigin = UTIL_EntityOrigin(m_pCharger);
 bot.setLookAt(vOrigin);

        if ( bot.distanceFrom(m_pCharger) > 56 )
        {
            bot.setMove(vOrigin);
            UTIL_DebugMsg(bot.m_pPlayer,"bot.setMove(m_pCharger.pev.origin)",DEBUG_TASK);
        }
        else
        {
            bot.StopMoving();
           
            UTIL_DebugMsg(bot.m_pPlayer,"bot.PressButton(IN_USE)",DEBUG_TASK);

            if ( Math.RandomLong(0,100) < 99 )
            {
                bot.PressButton(IN_USE);
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

        UTIL_DebugMsg(bot.m_pPlayer,"Health  = " + bot.m_pPlayer.pev.health);
        UTIL_DebugMsg(bot.m_pPlayer,"Max Health = " + bot.m_pPlayer.pev.max_health);

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
    float m_fStartTime = 0.0f;

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
        if ( m_fStartTime == 0.0f )
            m_fStartTime = g_Engine.time + 1.0f;
        else if ( m_fStartTime < g_Engine.time )
            Complete();

        if ( Math.RandomLong(0,100) > 50 )
            bot.PressButton(m_iButton);
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
    RCBotNavigator@ navigator = null;
    int m_iGoalWpt;
    EHandle m_pEntity;

    string DebugString ()
    {
        return "CFindPathTask";
    }

    /**
     * @param pEntity - Find moving target
     */ 
    CFindPathTask ( RCBot@ bot, int wpt, CBaseEntity@ pEntity = null )
    {
        m_pEntity = pEntity;
        m_iGoalWpt = wpt;
    }

    void execute ( RCBot@ bot )
    {
        if ( navigator is null )
            @navigator = RCBotNavigator(bot,m_iGoalWpt,m_pEntity.GetEntity());

        switch ( navigator.run(bot) )
        {
            case NavigatorState_Following:

            navigator.execute(bot);
            
            break;
        case NavigatorState_Complete:
 
            // follow waypoint
            UTIL_DebugMsg(bot.m_pPlayer,"NavigatorState_Complete",DEBUG_NAV);
        break;
        case NavigatorState_InProgress:
            // waiting...
             UTIL_DebugMsg(bot.m_pPlayer,"NavigatorState_InProgress",DEBUG_NAV);
        break;
        case NavigatorState_Fail:
             UTIL_DebugMsg(bot.m_pPlayer,"NavigatorState_Fail",DEBUG_NAV);
            Failed();
        break;
        case NavigatorState_ReachedGoal:

            UTIL_DebugMsg(bot.m_pPlayer,"NavigatorState_ReachedGoal",DEBUG_NAV);
            //m_pContainingSchedule.addTaskFront(CBotMoveToOrigin());
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
    CBotTaskFindCoverSchedule ( RCBot@ bot, Vector vHideFrom )
    {
        addTask(CBotTaskFindCoverTask(bot,vHideFrom));
        // reload when arrive at cover point
        addTask(CBotButtonTask(IN_RELOAD));
    }
    
}

class CGrappleTask : RCBotTask
{
    Vector m_vGrapple;
    Vector m_vTo;

    CGrappleTask ( Vector vGrapple, Vector vTo )
    {
        m_vGrapple = vGrapple;
        m_vTo = vTo;
        setTimeout(15.0f);
    }

    void execute ( RCBot@ bot )
    {
        CBotWeapon@ pGrapple = bot.getGrapple();
        CBaseEntity@ pPlayer = bot.m_pPlayer;

        if ( pGrapple is null )
        {
                Failed();
                return;
        }

        if ( !bot.isCurrentWeapon(pGrapple) )
        {
            bot.selectWeapon(pGrapple);
            return;
        }

        bot.StopMoving();
        bot.setLookAt(m_vGrapple);
        bot.PressButton(IN_ATTACK);

        if ( bot.distanceFrom(m_vTo) < pPlayer.pev.velocity.Length() )
        {                    
            Complete();
        }
    }

}

class CBotTaskRevivePlayer : RCBotTask 
{
    float m_fLastVisibleTime = 0.0f;
    EHandle m_pHeal;

    CBotTaskRevivePlayer ( CBaseEntity@ pHeal )
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

        if (!bot.CanRevive(pent) )
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

            // get down to ground revive
            bot.PressButton(IN_DUCK);

            if ( bot.distanceFrom(vHeal) > 64.0f )
            {
                bot.setMove(vHeal);
            }
            else
            {
                bot.PressButton(IN_ATTACK2);
                bot.StopMoving();
            }
        }
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

                UTIL_DebugMsg(bot.m_pPlayer,"bot.distanceFrom(m_vOrigin) > 96",DEBUG_TASK);
            }
            else 
            {
                CBaseEntity@ playerOnTop = UTIL_FindNearestPlayerOnTop(bot.m_pPlayer);

                if ( playerOnTop !is null  )
                {
                    UTIL_DebugMsg(bot.m_pPlayer,"playerOnTop !is null",DEBUG_TASK);

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
    CBotTaskFindCoverTask ( RCBot@ bot, Vector vHideFrom )
    {
        @finder = RCBotCoverWaypointFinder(g_Waypoints.m_VisibilityTable,bot,vHideFrom);    

        if ( finder.state == NavigatorState_Fail )
        {
            UTIL_DebugMsg(bot.m_pPlayer,"FINDING COVER FAILED!!!",DEBUG_TASK);
            Failed();
        }
    }


     void execute ( RCBot@ bot )
     {
         if ( finder.execute() )
         {
             m_pContainingSchedule.addTask(CFindPathTask(bot,finder.m_iGoalWaypoint));
             UTIL_DebugMsg(bot.m_pPlayer,"FINDING COVER COMPLETE!!!",DEBUG_TASK);
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

    string DebugMessage ()
    {
        return "CBotUtil";
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
        return 0.9f;
    }

    string DebugMessage ()
    {
        return "CBotHealPlayerUtil";
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

/**
 * CBotHealPlayerUtil
 *
 * Utility function for healing a living player with medikit
 */
class CBotRevivePlayerUtil : CBotUtil
{
    float calculateUtility ( RCBot@ bot )
    {        
        return 1.0f;
    }

    bool canDo (RCBot@ bot)
    {
        return (g_Engine.time > m_fNextDo) && bot.m_pRevive.GetEntity() !is null && bot.CanRevive(bot.m_pRevive.GetEntity());
    }    

    string DebugMessage ()
    {
        return "CBotRevivePlayerUtil";
    }    

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        CBaseEntity@ pHeal = bot.m_pRevive.GetEntity();

        if ( pHeal is null )
            return null;

        // Vector vecLocation, CBasePlayer@ player = null, int iIgnore = -1, float minDistance = 512.0f, bool bCheckVisible = true, bool bIgnoreUnreachable = true )
        int iWpt = g_Waypoints.getNearestWaypointIndex(pHeal.EyePosition(),pHeal,-1,400.0f,true,false); 

        if ( iWpt != -1 )
        {
            RCBotSchedule@ sched = RCBotSchedule();

            //RCBot@ bot, int wpt, CBaseEntity@ pEntity = nul
            sched.addTask(CFindPathTask(bot,iWpt,pHeal));
            sched.addTask(CBotTaskRevivePlayer(pHeal));

            return sched;
        }

        return null;
    }
}


class CBotGetHealthUtil : CBotUtil
{
    string DebugMessage ()
    {
        return "CBotGetHealthUtil";
    }    
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
    string DebugMessage ()
    {
        return "CBotGetWeapon";
    }

   float calculateUtility ( RCBot@ bot )
    {
        // TO DO calculate on bots current weapons collection
        float ret = 1.0 - bot.m_pWeapons.getNumWeaponsPercent(bot);
       
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
    string DebugMessage ()
    {
        return "CBotGetAmmo";
    }    
   float calculateUtility ( RCBot@ bot )
    {
        float ret = 1.0 - bot.m_pWeapons.getPrimaryAmmoPercent(bot);
       
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

class CBotMoveToOrigin : RCBotTask
{
    Vector m_vOrigin;

    CBotMoveToOrigin ( Vector vOrigin )
    {
        m_fTimeout = 3.0f;
        m_vOrigin = vOrigin;
    }

    void execute ( RCBot@ bot )
    {
        bot.setMove(m_vOrigin);

        if ( bot.distanceFrom(m_vOrigin) < 64 )
        {
            Complete();
        }
    }
}

class CBotWaitTask : RCBotTask
{
    CBotWaitTask ( float fTime = 0.0f )
    {
        m_fTimeout = fTime;
    }

    void execute (RCBot@bot )
    {
        bot.StopMoving();
    }
}

class CBotGetArmorUtil : CBotUtil
{
    string DebugMessage ()
    {
        return "CBotGetArmorUtil";
    }  
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
    string DebugMessage ()
    {
        return "CBotGotoObjectiveUtil";
    }  

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
    string DebugMessage ()
    {
        return "CBotFindLastEnemyUtil";
    }      
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
        // ( Vector vecLocation, CBaseEntity@ player = null, int iIgnore = -1, float minDistance = 512.0f, bool bCheckVisible = true, bool bIgnoreUnreachable = true )

        int iRandomGoal = g_Waypoints.getNearestWaypointIndex(bot.m_vLastSeeEnemy,null,-1,400.0,true,false);

        if ( iRandomGoal != -1 )
        {
            RCBotSchedule@ sched = RCBotSchedule();
            sched.addTask(CFindPathTask(bot,iRandomGoal,bot.m_pEnemy.GetEntity()));
            sched.addTask(CRemoveLastEnemy());

            return sched;
        }

        return null;
    }
}



class CBotGotoEndLevelUtil : CBotUtil
{
    CFailedWaypointsList failed;
    string DebugMessage ()
    {
        return "CBotGotoEndLevelUtil";
    }      
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
    string DebugMessage ()
    {
        return "CBotRoamUtil";
    }         
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
            m_Utils.insertLast(CBotRevivePlayerUtil());
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
               // UTIL_DebugMsg(bot.m_pPlayer,"Utility = " + m_Utils[i].utility);
                UtilsCanDo.insertLast(m_Utils[i]);
            }
        }

        if ( UtilsCanDo.length() > 0 )
        {
            UtilsCanDo.sort(function(a,b) { return a.utility > b.utility; });

            for ( uint i = 0; i < UtilsCanDo.length(); i ++ )
            {
                CBotUtil@ chosenUtil = UtilsCanDo[i];
                RCBotSchedule@ sched = chosenUtil.execute(bot);

                if ( sched !is null )
                {                    
                    UTIL_DebugMsg(bot.m_pPlayer,"Chosen Utility = " + chosenUtil.DebugMessage() + " Value = " + chosenUtil.utility, DEBUG_UTIL );
                    chosenUtil.setNextDo();

                    return sched;
                }
            }
        }
        else
            reset();

        return null;
    }
}