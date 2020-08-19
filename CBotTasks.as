
const float REACHABLE_PICKUP_RANGE = 200.0f;
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

    string getCurrentTask ()
    {
        if ( m_pTasks.length() > 0)
        {
            return m_pTasks[0].DebugString();
        }

        return "null";
    }

	int execute (RCBot@ bot)
	{        
        //UTIL_DebugMsg(bot.m_pPlayer,"execute()",DEBUG_TASK);
        if ( m_pTasks.length() == 0 )
        {
            UTIL_DebugMsg(bot.m_pPlayer,"execute() m_pTasks.length() == 0",DEBUG_TASK);
            return SCHED_TASK_OK;
        }

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
            else
            {
                UTIL_DebugMsg(bot.m_pPlayer,"m_pCurrentTask.m_bComplete",DEBUG_TASK);
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
            UTIL_DebugMsg(bot.m_pPlayer,m_pCurrentTask.DebugString()+" FAILED",DEBUG_TASK);

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

        @pent = UTIL_FindNearestEntity("func_healthcharger",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

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
            if ( bot.distanceFrom(pent) < REACHABLE_PICKUP_RANGE )
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

        // nothing to pick up -- maybe a resupply?
        @pent = UTIL_FindNearestEntity("func_button",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

        if ( pent is null )
            @pent = UTIL_FindNearestEntity("func_door",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

        if ( pent is null )
            @pent = UTIL_FindNearestEntity("func_rot_button",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

        if ( pent !is null )
        {
            UTIL_DebugMsg(bot.m_pPlayer,"nothing to pick up -- maybe a resupply?",DEBUG_TASK);	

            m_pContainingSchedule.addTask(CUseButtonTask(pent));

            Complete();          
            return;
        }        
        
        UTIL_DebugMsg(bot.m_pPlayer,"nothing FOUND",DEBUG_TASK);

        Failed();
    }
}

final class CBotTaskWait : RCBotTask
{
     float m_fWaitTime = 0.0f;
     float m_fWait = 0.0f;
     Vector m_vFace;

     CBotTaskWait ( float fWaitTime, Vector vface )
     {
         m_fWait = fWaitTime;
         m_vFace = vface;
     }

    string DebugString ()
    {
        return "CBotTaskWait";
    }

    void execute ( RCBot@ bot )
    {
        if ( m_fWaitTime == 0.0f )
            m_fWaitTime = g_Engine.time + m_fWait;
        else if ( m_fWaitTime < g_Engine.time )
            Complete();

        //UTIL_PrintVector("m_vFace",m_vFace);
        bot.setLookAt(m_vFace,PRIORITY_OVERRIDE+3);

        bot.StopMoving();
    }
}

//CBasePlayer@ UTIL_FindNearestPlayer ( Vector vOrigin,
// float minDistance = 512.0f, CBasePlayer@ ignore = null, bool onGroundOnly = false )
final class CBotTaskWaitNoPlayer : RCBotTask
{
    Vector m_vOrigin;
    float m_fWaitTime;
    EHandle pNearestPlayer;

    CBotTaskWaitNoPlayer(Vector vOrigin)
    {
        m_vOrigin = vOrigin;
        m_fWaitTime = 0.0f;
        pNearestPlayer = null;
    }

    string DebugString ()
    {
        return "CBotTaskWaitNoPlayer";
    }

    void execute ( RCBot@ bot )
    {
        CBaseEntity@ pNearest;

        if ( m_fWaitTime == 0.0f ) 
        {
            pNearestPlayer = UTIL_FindNearestPlayer(m_vOrigin,128.0f,bot.m_pPlayer,false,true);
            m_fWaitTime = g_Engine.time + 3.0f;            
        }

        @pNearest = pNearestPlayer.GetEntity();

        if ( pNearest is null )
        {
            Complete();            
            return;
        }

        if ( pNearest.pev.velocity.Length() > 0 && bot.isEntityVisible(pNearest) )
        {
            m_fWaitTime = g_Engine.time + 3.0f;
        }

        if ( m_fWaitTime < g_Engine.time )
        {
            Complete();
             return;
        }

        if ( (pNearest.pev.origin - m_vOrigin).Length() > 128 )
        {
            Complete();
            return;
        }
         // look at player
         bot.setLookAt(pNearest.pev.origin);

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
        
        while ( (@pent = g_EntityFuncs.FindEntityInSphere(pent, bot.m_pPlayer.pev.origin, 128,"ammo_*", "classname" )) !is null )
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
        else
        {
            // nothing to pick up -- maybe a resupply?
            @pent = UTIL_FindNearestEntity("func_button",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);
        if ( pent is null )
            @pent = UTIL_FindNearestEntity("func_door",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);
           if ( pent is null )
            @pent = UTIL_FindNearestEntity("func_rot_button",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

            if ( pent !is null )
            {
                UTIL_DebugMsg(bot.m_pPlayer,"nothing to pick up -- maybe a resupply?",DEBUG_TASK);	

                m_pContainingSchedule.addTask(CUseButtonTask(pent));

                Complete();          
                return;
            }
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
        
        while ( (@pent = g_EntityFuncs.FindEntityInSphere(pent, bot.m_pPlayer.pev.origin, REACHABLE_PICKUP_RANGE,"weapon_*", "classname" )) !is null )
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

        @pent = UTIL_FindNearestEntity("func_recharge",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

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
            if ( bot.distanceFrom(pent) < REACHABLE_PICKUP_RANGE )
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

        // nothing to pick up -- maybe a resupply?
        @pent = UTIL_FindNearestEntity("func_button",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);
        if ( pent is null )
            @pent = UTIL_FindNearestEntity("func_door",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);
         if ( pent is null )
            @pent = UTIL_FindNearestEntity("func_rot_button",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

        if ( pent !is null )
        {
            UTIL_DebugMsg(bot.m_pPlayer,"nothing to pick up -- maybe a resupply?",DEBUG_TASK);	

            m_pContainingSchedule.addTask(CUseButtonTask(pent));

            Complete();          
            return;
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

        if ( pItem is null )
        {
            Complete();
            return;
        }

        UTIL_DebugMsg(bot.m_pPlayer,"CPickupItemTask",DEBUG_TASK);

        // can't pick this up!!!
        if ( pItem.pev.owner !is null )
            Complete();

        if ( pItem.pev.effects & EF_NODRAW == EF_NODRAW )
        {
            UTIL_DebugMsg(bot.m_pPlayer,"EF_NODRAW",DEBUG_TASK);
            Complete();
        }

        bot.setLookAt(UTIL_EntityOrigin(pItem));

        if ( bot.distanceFrom(pItem) > 56 )
        {
            bot.setMove(pItem.pev.origin);

            UTIL_DebugMsg(bot.m_pPlayer,"bot.setMove(m_pItem.pev.origin);",DEBUG_TASK);
        }
        else
        {
            // if it's a minigun -- need to press USE to pick up
            if ( pItem.GetClassname() == "weapon_minigun" )
                bot.PressButton(IN_USE);

            Complete();
        }
    }
}

final class CCheckObjectiveTask : RCBotTask
{
    int m_iWpt;

    CCheckObjectiveTask ( int iWptObjective )
    {
        m_iWpt = iWptObjective;
    }

    string DebugString ()
    {
        return "CCheckObjectiveTask";
    }
    void execute ( RCBot@ bot )
    {
        switch ( g_WaypointScripts.canDoObjective(bot.m_pPlayer,m_iWpt) )				
        {
            case BotWaypointScriptResult_Error:
            case BotWaypointScriptResult_Incomplete:
          
                m_pContainingSchedule.addTask(CFindButtonTask());
            break;
            default:
            break;
        }

        Complete();
    }
}

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
        CBaseEntity@ pent = UTIL_FindNearestEntity("func_button",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

        if ( pent !is null )
        {
                        UTIL_DebugMsg(bot.m_pPlayer,"func_button",DEBUG_TASK);
                        // add Task to pick up health
                        m_pContainingSchedule.addTask(CUseButtonTask(pent));
                        Complete();
                        return;                                    
        }

        @pent = UTIL_FindNearestEntity("button_target",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

        if ( pent !is null )
        {
                        UTIL_DebugMsg(bot.m_pPlayer,"button_target",DEBUG_TASK);
                        // add Task to pick up health
                        m_pContainingSchedule.addTask(CUseButtonTask(pent));
                        Complete();
                        return;                                    
        }        

        @pent = UTIL_FindNearestEntity("func_rot_button",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

        if ( pent !is null )
        {
                UTIL_DebugMsg(bot.m_pPlayer,"func_rot_button",DEBUG_TASK);
                // add Task to pick up health
                m_pContainingSchedule.addTask(CUseButtonTask(pent));
                Complete();
                return;                                    
        }

        @pent = UTIL_FindNearestEntity("func_door_rotating",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

        if ( pent !is null )
        {
                        UTIL_DebugMsg(bot.m_pPlayer,"func_door_rotating",DEBUG_TASK);
                        // add Task to pick up health
                        m_pContainingSchedule.addTask(CUseButtonTask(pent));
                        Complete();
                        return;                                    
        }

         @pent = UTIL_FindNearestEntity("momentary_rot_button",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

        if ( pent !is null )
        {
                        UTIL_DebugMsg(bot.m_pPlayer,"momentary_rot_button",DEBUG_TASK);
                        // add Task to pick up health
                        m_pContainingSchedule.addTask(CUseButtonTask(pent));
                        Complete();
                        return;                                    
        }     
        
         @pent = UTIL_FindNearestEntity("trigger_once",bot.m_pPlayer.EyePosition(),REACHABLE_PICKUP_RANGE,true,false);

        if ( pent !is null )
        {
                        UTIL_DebugMsg(bot.m_pPlayer,"trigger_once",DEBUG_TASK);
                        // add Task to pick up health
                        m_pContainingSchedule.addTask(CBotMoveToOrigin(UTIL_EntityOrigin(pent)));
                        Complete();
                        return;                                    
        }
   

        Failed();
    }
}

final class CLongjumpTask: RCBotTask
{
    float m_fCrouchtime = 0.0f;
    Vector m_vTo;
    CLongjumpTask (Vector vTo)
    {
        m_vTo = vTo;
    }

    bool jump = false;

    void execute ( RCBot@ bot )
    {
        bot.setMove(m_vTo);

        if ( jump == false )
        {
           // BotMessage("velocity = " + bot.m_pPlayer.pev.velocity.Length2D()+"\r\n");
            if ( bot.m_pPlayer.pev.velocity.Length2D() > 80 ) // minimum long jump speed
                jump = true;
        }
        else 
        {           
           // BotMessage("DUCK\r\n");
            bot.PressButton(IN_DUCK);

            if ( m_fCrouchtime == 0.0f )
                m_fCrouchtime = g_Engine.time + 0.25f;
            if ( m_fCrouchtime < g_Engine.time )
            {
                bot.Jump();
                Complete();
            }
        }
        
        
    }
}

final class CUseButtonTask : RCBotTask
{
    EHandle m_pButton;
    bool m_bIsMomentary;
    bool m_bMomentaryStarted;
    float m_fMomentaryHoldTime;
    Vector vOrigin;
    bool m_bIsShootable;
    int prev_frame = 0;
    
    string DebugString ()
    {
        return "CUseButtonTask";
    }

    CUseButtonTask ( CBaseEntity@ button )
    {
        m_pButton = button;

        prev_frame = int(button.pev.frame);

        m_fMomentaryHoldTime = 0.0f;

        m_bIsShootable = button.pev.health>0;

        vOrigin = UTIL_EntityOrigin(button);
        
        m_bIsMomentary = (button.GetClassname() == "momentary_rot_button")||(button.GetClassname() == "func_rot_button");

        if ( m_bIsMomentary )
            m_fDefaultTimeout = 20.0f;
        else
        {
            m_fDefaultTimeout = 10.0f;
            vOrigin = vOrigin + Vector(0,0,Math.RandomFloat(-button.pev.size.z/4,button.pev.size.z/4));
        }

        m_bMomentaryStarted = false;
    } 

    void execute ( RCBot@ bot )
    {
        CBaseEntity@ pButton = m_pButton.GetEntity();
        CBotWeapon@ pBestWeapon = null;

        if ( pButton is null )
        {
            Complete();
            return;
        }

        @pBestWeapon = bot.m_pWeapons.findBestWeapon(bot,UTIL_EntityOrigin(pButton),pButton);        
       
        float fButtonVelocity = pButton.pev.avelocity.Length();

        if ( pButton.pev.frame != int(prev_frame) )
            Complete();
        else if ( m_bIsMomentary && m_bMomentaryStarted )
        {
            if ( fButtonVelocity == 0.0 )
            {
                if ( m_fMomentaryHoldTime == 0.0 )
                    m_fMomentaryHoldTime = g_Engine.time + Math.RandomFloat(3.0f,10.0f);
                else if ( m_fMomentaryHoldTime < g_Engine.time )   
                    Complete();
            }
        }

        bot.setLookAt(vOrigin,PRIORITY_TASK+1);

        if ( m_bIsShootable )
        {
            if ( pBestWeapon !is null && !bot.isCurrentWeapon(pBestWeapon) )
            {
                bot.selectWeapon(pBestWeapon);            
                return;
            }     
        }

        if ( (!m_bIsShootable||(pBestWeapon is null)||pBestWeapon.IsMelee()) && (vOrigin-bot.m_pPlayer.pev.origin).Length2D() > 70 )
        {
            bot.setMove(vOrigin);
            UTIL_DebugMsg(bot.m_pPlayer,"bot.setMove(vOrigin)",DEBUG_TASK);
        }
        else
        {           
            bot.StopMoving();

            if ( vOrigin.z > (bot.m_pPlayer.EyePosition().z+72) )
            {
                //fail too high
                Failed();
                return;
            }

            if ( vOrigin.z > (bot.m_pPlayer.EyePosition().z+8) )
            {
                if ( Math.RandomLong(0,100) > 50 )
                    bot.PressButton(IN_JUMP);
            }            

             if ( bot.m_pPlayer.FInViewCone(pButton) )
             {
                UTIL_DebugMsg(bot.m_pPlayer,"bot.PressButton(IN_USE)",DEBUG_TASK);            

                if ( m_bIsMomentary || ( Math.RandomLong(0,100) < 50)  )
                {
                    if ( m_bIsShootable )
                    {
                        bot.PressButton(IN_ATTACK);
                    }
                    else                         
                        bot.PressButton(IN_USE);

                    if ( !m_bIsMomentary )
                        vOrigin = UTIL_EntityOrigin(pButton) + Vector(0,0,Math.RandomFloat(-pButton.pev.size.z/4,pButton.pev.size.z/4));
                }
             }

            if (fButtonVelocity>0.0f)
                m_bMomentaryStarted = true;
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
        if ( bot.m_pPlayer.pev.armorvalue >= bot.m_pPlayer.pev.armortype )
        {
            Complete();
            UTIL_DebugMsg(bot.m_pPlayer," bot.m_pPlayer.pev.armorvalue >= armortype",DEBUG_TASK);
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
        // Don't reload if I'm shooting!!!!
        if ( m_iButton == IN_RELOAD )
        {
            if ( bot.hasEnemy() )
            {
                Failed();
                return;
            }
        }

        if ( m_fStartTime == 0.0f )
            m_fStartTime = g_Engine.time + Math.RandomLong(2.0,4.0);
        else if ( m_fStartTime < g_Engine.time )
            Complete();
        bot.StopMoving();
        
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
    OnPathFail@ failCommand;

    string DebugString ()
    {
        return "CFindPathTask";
    }

    /**
     * @param pEntity - Find moving target
     */ 
    CFindPathTask ( RCBot@ bot, int wpt, CBaseEntity@ pEntity = null, OnPathFail@ onFail = null )
    {
        m_pEntity = pEntity;
        m_iGoalWpt = wpt;
        bot.m_iGoalWaypoint = m_iGoalWpt;
        @failCommand= onFail;
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
            // found goal 
            // path find didn't fail
            @failCommand = null;
            // waiting...
             UTIL_DebugMsg(bot.m_pPlayer,"NavigatorState_InProgress",DEBUG_NAV);
        break;
        case NavigatorState_Fail:
            if ( failCommand !is null )
                failCommand.execute();

             UTIL_DebugMsg(bot.m_pPlayer,"NavigatorState_Fail",DEBUG_NAV);
            Failed();
            bot.failedPath(true);
        break;
        case NavigatorState_ReachedGoal:

            UTIL_DebugMsg(bot.m_pPlayer,"NavigatorState_ReachedGoal",DEBUG_NAV);
            bot.reachedGoal();
            Complete();
            break;
        }
    }
}

class CFindPathSchedule : RCBotSchedule
{
    CFindPathSchedule ( RCBot@ bot, int iWpt, CObjectivePathFail@ failCommand = null )
    {
        addTask(CFindPathTask(bot,iWpt,null,failCommand));
    }
}

class CThrowGrenadeSchedule : RCBotSchedule 
{
    CThrowGrenadeSchedule ( RCBot@ bot, Vector vThrowTo )
    {       
        addTask(CBotThrowGrenade(bot,vThrowTo));
        addTask(CBotTaskFindCoverTask(bot,vThrowTo));
        addTask(CBotTaskWait(1.0,vThrowTo));
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

class CBotThrowGrenade : RCBotTask
{
    Vector vThrowTo;
    float m_fWaitTime;

    int MAX_GREN_THROW_DIST = 800;

    CBotThrowGrenade ( RCBot@ bot, Vector throwTo )
    {
        float distance = bot.distanceFrom(throwTo);
        
        float fFraction = distance/MAX_GREN_THROW_DIST;
        m_fWaitTime = 0.0f;
        vThrowTo = throwTo;
		// add gravity offset
		vThrowTo.z += (800 *  Math.RandomFloat(0.8f,1.2f) * fFraction);      
    }

    string DebugString ()
    {
        return "CBotThrowGrenade";
    }

    void execute ( RCBot@ bot )
    {
        CBotWeapon@ pGrenade = bot.getGrenade();
        CBaseEntity@ pPlayer = bot.m_pPlayer;

          // stop bot from attacking enemies whilst healing
        bot.ceaseFire(true);

        if ( pGrenade is null )
        {
                Failed();
                return;
        }

        if ( pGrenade.getPrimaryAmmo(bot) == 0 )
        {
            Failed();
            return;
        }        

        if ( !bot.isCurrentWeapon(pGrenade) )
        {
            bot.selectWeapon(pGrenade);
            return;
        }

        bot.StopMoving();
        bot.setLookAt(vThrowTo);

         if ( m_fWaitTime == 0.0f )
            m_fWaitTime = g_Engine.time + 1.0f; // hold for one second
        else if ( m_fWaitTime < g_Engine.time )
        {
            Complete();        
            // stop bot from attacking enemies whilst healing
            bot.ceaseFire(false);

        }
        else // else hold the button
            bot.PressButton(IN_ATTACK);
        
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
    string DebugString ()
    {
        return "CGrappleTask";
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

class CBotPlaceTripmine : RCBotTask 
{
    CBotPlaceTripmine ( Vector vPlane, Vector vNormal )
    {

    }
    string DebugString ()
    {
        return "CBotPlaceTripmine";
    }

    void execute ( RCBot@ bot )
    {

    }
}

class CBotPlaceExplosive : RCBotTask 
{
    CBotPlaceExplosive ( Vector vTarget )
    {

    }
    string DebugString ()
    {
        return "CBotPlaceExplosive";
    }
    void execute ( RCBot@ bot )
    {
        
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
    string DebugString ()
    {
        return "CBotTaskRevivePlayer";
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
        bot.setLookAt(vHeal,PRIORITY_OVERRIDE);

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

class CBotTaskFollow : RCBotTask
{
    EHandle m_pFollow;
    bool LostPlayer = false;
    float m_fLastVisibleTime;
    string DebugString ()
    {
        return "CBotTaskRevivePlayer";
    }
     CBotTaskFollow ( CBaseEntity@ pFollow, bool lostPlayer )
     {
         m_pFollow = pFollow;
         m_fLastVisibleTime = 0.0f;
         LostPlayer = lostPlayer;
     }

     void execute ( RCBot@ bot )
     {
         Vector vFollow;
         CBaseEntity@ pFollow;

         @pFollow = m_pFollow.GetEntity();

         if ( pFollow is null )
         {
            Failed();
            return;
         }
         
        if ( m_fLastVisibleTime == 0.0f )
            m_fLastVisibleTime = g_Engine.time + 3.0f;
        else if ( bot.isEntityVisible(pFollow) )
        {
            m_fLastVisibleTime = g_Engine.time + 1.0f;
            LostPlayer = false;
        }
        else if ( m_fLastVisibleTime < g_Engine.time )
        {
            if ( !LostPlayer )
            {
                int iWpt = g_Waypoints.getNearestWaypointIndex(UTIL_EntityOrigin(pFollow),null,-1,400.0,true,false);

                if ( iWpt == -1 )
                {
                    Failed();
                }
                else 
                {
                    m_pContainingSchedule.addTask(CFindPathTask(bot,iWpt,pFollow));                
                    m_pContainingSchedule.addTask(CBotTaskFollow(pFollow,true));
                    Complete();
                }
            }
            else 
                Failed();
            return;
        }

        vFollow = UTIL_EntityOrigin(pFollow);

        bot.setLookAt(vFollow);

        if ( bot.distanceFrom(vFollow) > 128 )
            bot.setMove(vFollow);
     }
}

class CBotTaskUseNPC : RCBotTask
{
    EHandle m_pNPC;
    string DebugString ()
    {
        return "CBotTaskUseNPC";
    }
    CBotTaskUseNPC ( CBaseEntity@ NPC )
    {
        m_pNPC = NPC;
    }

    void execute ( RCBot@ bot )
    {
        CBaseEntity@ NPC = m_pNPC.GetEntity();
        Vector vNPC;

        if ( NPC is null )
        {
            //UTIL_DebugMsg ( CBaseEntity@ debugBot, string message, int level = 0 )
            UTIL_DebugMsg ( bot.m_pPlayer, "NPC is null", DEBUG_TASK );

            Failed();

            return;

        }

        CBaseMonster@ NPCm = cast<CBaseMonster@>(NPC);

        /*if ( !NPCm.CanPlayerFollow() )
        {
            Failed();

            UTIL_DebugMsg ( bot.m_pPlayer, "!NPCm.CanPlayerFollow()", DEBUG_TASK );
            return;
        }*/

        if ( NPCm.IsPlayerFollowing() )
        {
            Complete();
            bot.setFollowingNPC(NPC);

            UTIL_DebugMsg ( bot.m_pPlayer, "NPCm.IsPlayerFollowing()  Complete()", DEBUG_TASK );
            return;
        }

        vNPC = UTIL_EntityOrigin(NPC);

        bot.setLookAt(vNPC);

        if ( bot.distanceFrom(vNPC) > 80 )
        {
            bot.setMove(vNPC);            
        }
        else
        {
            if ( Math.RandomFloat(0,100) > 50 )
                bot.PressButton(IN_USE);
        }
    }

}

class CBotWaitForEntity : RCBotTask 
{
    EHandle m_pEntity;
    float m_fDist;

    string DebugString ()
    {
        return "CBotWaitForEntity";
    } 

     CBotWaitForEntity ( CBaseEntity@ pEntity, float fDist )
     {   
        m_fDist = fDist;
        m_pEntity = pEntity;
        setTimeout(Math.RandomFloat(9.0f,11.0f));    
     }

     void execute ( RCBot@ bot )
     {
         CBaseEntity@ pent = m_pEntity.GetEntity();

         if ( pent !is null )
         {
            if ( pent.pev.velocity.Length() < 1 )
            {
                Complete();
            }

            bot.StopMoving();
            bot.setLookAt(UTIL_EntityOrigin(pent));
         }
         else
            Failed();
     }
}

class CBotWaitPlatform : RCBotTask
{ 
    Vector m_vOrigin;
    float m_fHeightCheck;

    string DebugString ()
    {
        return "CBotWaitPlatform";
    } 

     CBotWaitPlatform ( Vector vPlatform )
     {
        m_vOrigin = vPlatform;       
        setTimeout(Math.RandomFloat(9.0f,11.0f));   
        m_fHeightCheck = Math.RandomFloat(64.0f,96.0f); 
     }

     void execute ( RCBot@ bot )
     {
         CBaseEntity@ pent = null;

         bot.StopMoving();

        TraceResult tr;

        g_Utility.TraceLine( m_vOrigin, m_vOrigin-Vector(0,0,m_fHeightCheck), ignore_monsters,dont_ignore_glass, bot.m_pPlayer.edict(), tr );

        bot.setLookAt(m_vOrigin);

        if ( tr.flFraction < 1.0 && tr.pHit !is null )
        {
            bot.m_flJumpPlatformTime = g_Engine.time + 3.0f;
            @bot.m_pExpectedPlatform = g_EntityFuncs.Instance(tr.pHit);
            Complete();
        }
     }
}

class CBotTaskUseTank : RCBotTask
{

    EHandle m_pTank;
    float m_fUseTankTime;    

     CBotTaskUseTank ( CBaseEntity@ pTank )
     {
         m_fUseTankTime = 0.0f;

         m_pTank = pTank;
     }

          string DebugString ()
    {
        return "CBotTaskUseTank";
    } 

     void execute ( RCBot@ bot )
     {
         CBaseTank@ pTank = cast<CBaseTank@>( m_pTank.GetEntity());

         if ( pTank is null )
         {        
             Failed();
             BotMessage("pTank is null");
             return;
         }

         if ( pTank.GetController() !is null )
         {
            if ( pTank.GetController() !is bot.m_pPlayer )
            {
                Failed();
                  BotMessage(" pTank.GetController() !is bot.m_pPlayer ");
                return;
            }
            // controlling tank
            else
            {
                if ( m_fUseTankTime == 0.0f )
                    m_fUseTankTime = g_Engine.time + 30.0f;
                else if ( m_fUseTankTime < g_Engine.time )
                {
                    // stop using tank
                    bot.PressButton(IN_USE);
                     BotMessage(" m_fUseTankTime < g_Engine.time  ");
                    Complete();
                }

                // don't use normal weapons
                bot.ceaseFire(true);
                bot.StopMoving();
                
                // check for enemies
                if ( bot.hasEnemy() )
                {
                    bot.setLookAt(UTIL_EntityOrigin(bot.getEnemy()));
                    bot.PressButton(IN_ATTACK);
                }
            }
         }
         else
         {
        
            if ( Math.RandomLong(0,100)> 50 )
                bot.PressButton(IN_USE);
        

            bot.setLookAt(UTIL_EntityOrigin(pTank));
            
         }

         // check if tank is being used 
     }
}
/*
class CBotTaskClimbLadder : RCBotTask
{
    bool isGoingUp = false;
    Vector m_vStart;
    Vector m_vEnd;
    Vector m_vAngles;
    int state = 0;

    CBotTaskClimbLadder ( Vector vLadderStart, Vector vLadderEnd )
    {
        m_vStart = vLadderStart;
        m_vEnd = vLadderEnd;

        isGoingUp = ( m_vEnd.z > m_vStart.z );

        m_vAngles = Math.VecToAngles( vLadderEnd - vLadderStart );
    }

     void execute ( RCBot@ bot )
     {

        switch ( state )
        {
            case 0:
                // look at end point from start

        }
        
     }  
}*/

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

     string DebugString ()
    {
        return "CBotTaskHealPlayer";
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

        // Look at player!!! FFSS!!!! LOOK AT THE PLAYER!!!
        bot.setLookAt(vHeal,PRIORITY_OVERRIDE+2); // + INFINITY!!!

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

    enum State_Role
  {
    State_DetectRole,
    State_Role_Below,
    State_Role_OnTop,
    State_Role_OnTop_MoveToGoal
  };
class CBotHumanTowerTask : RCBotTask
{
    Vector m_vGround;
    Vector m_vGoal;
    int m_iFlags;
    float m_fTime;
    float m_fJumpTime;

    string DebugString ()
    {
        string ret = "CBotHumanTowerTask (";

         switch ( State )
         {
            case State_DetectRole:
            ret += "State_DetectRole)";
            break;
            case State_Role_Below:
ret += "State_Role_Below)";
            break;
            case State_Role_OnTop:
ret += "State_Role_OnTop)";
            break;
            case State_Role_OnTop_MoveToGoal:
ret += "State_Role_OnTop_MoveToGoal)";
            break;
         }

        return ret;
    } 

    CBotHumanTowerTask ( Vector vGround, Vector vGoal, int iFlags )
    {
        m_vGround = vGround;
        m_vGoal = vGoal;
       // setTimeout(15.0f);
        m_fTime = 0.0f;
        m_fJumpTime = 0.0f;
        m_iFlags=iFlags;
    }

   
   State_Role State = State_DetectRole;
   
     void execute ( RCBot@ bot )
     {
         CBasePlayer@ groundPlayer = UTIL_FindNearestPlayer(m_vGround,64,bot.m_pPlayer,true,false,FL_ONGROUND&FL_DUCKING);
// search for a player near the ground point, ignoring me
            
         switch ( State )
         {
             case State_DetectRole:
                m_fTime = g_Engine.time+Math.RandomFloat(10.0,20.0);
                if ( groundPlayer is null )
                {
                    State = State_Role_Below;
                }
                else 
                    State = State_Role_OnTop;
             break;
             case State_Role_Below:

                if ( m_fTime < g_Engine.time && groundPlayer !is null )
                {                                 
                    State = State_DetectRole;
                    break;
                }
                // go to ground position and crouch until player is on top of me
                if ( bot.distanceFrom(m_vGround) > 64 )
                    bot.setMove(m_vGround);
                else 
                {
                    CBaseEntity@ playerOnTop = UTIL_FindNearestPlayerOnTop(bot.m_pPlayer);
                    
                    bot.StopMoving();

                    // if I have a player on top, stop crouching
                    if ( playerOnTop is null  )       
                    {             
                         bot.PressButton(IN_DUCK);
                         // BotMessage("ducking...");
                    }
                    else 
                        bot.setLookAt(UTIL_EntityOrigin(playerOnTop));
                     //else                         
				     //   BotMessage("playerOnTop is NOT NULL!!!!");
                }
             break;
             case State_Role_OnTop:
               
                if ( groundPlayer is null )
                {
                    // wrong role
                  
                        State = State_DetectRole;
                }
                else 
                {
                    if ( bot.m_pPlayer.pev.groundentity !is null )
                    {
                        if ( bot.m_pPlayer.pev.groundentity.vars.flags & FL_CLIENT == FL_CLIENT )
                        {
                            State = State_Role_OnTop_MoveToGoal;
                            m_fJumpTime = g_Engine.time + Math.RandomLong(3.0,6.0);
                            break;
                        }
                    }

                    Vector vOrigin = UTIL_EntityOrigin(groundPlayer);

                    bot.setLookAt(vOrigin);
                    bot.setMove(vOrigin);

                   
                    if ( Math.RandomLong(0,100) > 50 )
                        bot.PressButton(IN_JUMP);
                                
                }

             break;
             case State_Role_OnTop_MoveToGoal:

                if ( m_fJumpTime < g_Engine.time )
                {
                    State = State_DetectRole;
                    break;
                }

                bot.setMove(m_vGoal);
                bot.setLookAt(m_vGoal);
                
                if ( Math.RandomLong(0,100) > 50 )
                    bot.PressButton(IN_JUMP);

                if ( bot.distanceFrom(m_vGoal) < 64 )
                    Complete();

                if ( m_iFlags & W_FL_CROUCH == W_FL_CROUCH )
                    bot.PressButton(IN_DUCK);

             break;
         }
   
     }
}

class CBotTaskUseTeleporter : RCBotTask
{
    Vector m_vTeleport;
    Vector m_vDestination;

    string DebugString ()
    {
        return "CBotTaskUseTeleporter";
    } 

    CBotTaskUseTeleporter ( Vector vTeleport, Vector vDestination )
    {
        m_vTeleport = vTeleport;
        m_vDestination = vDestination;
        setTimeout(5.0f);
    }

    void execute ( RCBot@ bot )
    {
        float teleDist = bot.distanceFrom(m_vTeleport);
        float destDist = bot.distanceFrom(m_vDestination);

        if ( destDist < teleDist )
        {
           // BotMessage("destDist is " + destDist + " teleDist is " + teleDist);
            Complete();
        }
        else 
        {
            if ( teleDist < 16 )
                bot.StopMoving();
            else
                bot.setMove(m_vTeleport);
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

    //float m_fWeight;
    //int m_iNumTimesChosenThisLife;
    //float m_iPreviousScore;

    CBotUtil ( ) 
    { 
        utility = 0; 
       // m_fWeight = 1.0f;
        m_fNextDo = 0.0;   
       // m_iPreviousScore = 0;
        //m_iNumTimesChosenThisLife = 0;
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

    /*float getWeight ()
    {
        return m_fWeight;
    }*/

    /*void chosen ()
    {
        m_iNumTimesChosenThisLife++;
    }*/

    /*void calculateWeight (RCBot@ bot, int iNumUtilsChosen)
    {
        float iCurrentScore = bot.m_pPlayer.pev.frags;
 
        if ( iNumUtilsChosen > 0 && m_iNumTimesChosenThisLife > 0 )
        {
            float fWeightAdjustment;
            bool bGoodUtil = ( iCurrentScore > m_iPreviousScore );
            
            if ( m_iNumTimesChosenThisLife == iNumUtilsChosen )
            {
                // BotMessage("m_iNumTimesChosenThisLife == iNumUtilsChosen");
                fWeightAdjustment = 1.0f;
            }
            else 
            {
                fWeightAdjustment = float(m_iNumTimesChosenThisLife)/iNumUtilsChosen;
                // BotMessage("fWeightAdjustment = " + fWeightAdjustment);
            }

            if ( bGoodUtil )
            {                
                m_fWeight += (fWeightAdjustment*0.1f);
                // BotMessage("bGoodUtil == true");
            }
            else 
            {
                
                m_fWeight -= (fWeightAdjustment*0.1f);
                // BotMessage("bGoodUtil == false");
            }
            if ( m_fWeight > 2.0f ) // maximum weight
                m_fWeight = 2.0f; 
            else if ( m_fWeight < 0.25f ) // minimum weight
                m_fWeight = 0.25f;

            UTIL_DebugMsg(bot.m_pPlayer,"New Weight (" + DebugMessage() + ") is " + m_fWeight,DEBUG_UTIL );
        }
     
        iNumUtilsChosen = 0;
        m_iNumTimesChosenThisLife = 0;
        m_iPreviousScore = iCurrentScore;                       
    }*/

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
        return 0.99f - (bot.m_pEnemiesVisible.EnemiesVisible()*0.1f);
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

class CBotFindCoverUtil : CBotUtil
{
    float calculateUtility ( RCBot@ bot )
    {        
        return (1.0f - bot.HealthPercent()) * bot.m_pEnemiesVisible.EnemiesVisible();
    }    

    bool canDo (RCBot@ bot)
    {
        if  ( bot.m_pEnemy.GetEntity() !is null && bot.m_pEnemiesVisible.EnemiesVisible() > 0 ) 
            return CBotUtil::canDo(bot);

        return false;
    }

    string DebugMessage ()
    {
        return "CbotFindCoverUtil";
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        Vector vHideFrom = UTIL_EntityOrigin(bot.m_pEnemy.GetEntity());

        RCBotSchedule@ sched = CBotTaskFindCoverSchedule(bot,vHideFrom);
        return sched;
    } 
    
}

class CBotThrowGrenadeUtil : CBotUtil
{
     Vector vLastSeeEnemy;
    string DebugMessage ()
    {
        return "CBotThrowGrenadeUtil";
    }

    float calculateUtility ( RCBot@ bot )
    {        
        return 1.0f;
    }    

    bool canDo (RCBot@ bot)
    {
        if ( bot.getGrenade() !is null )
        {
            BotEnemyLastSeen@ nearestLastSeen = bot.m_pEnemiesVisible.nearestEnemySeen(bot);

            if ( nearestLastSeen !is null )
            {
                vLastSeeEnemy = nearestLastSeen.getGrenadePosition();

                if ( vLastSeeEnemy.z > (bot.m_pPlayer.pev.origin.z+128) )
                    return false; // can't throw high

                float distance = bot.distanceFrom(vLastSeeEnemy);
                
                if ( UTIL_IsVisible(bot.m_pPlayer.pev.origin, bot.m_vLastSeeEnemy, bot.m_pPlayer) && bot.m_bLastSeeEnemyValid && (distance > 300) && (distance<1000) )
                {
                    return CBotUtil::canDo(bot);
                }
            }
        }

        return false;
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        RCBotSchedule@ sched = CThrowGrenadeSchedule(bot,vLastSeeEnemy);
        return sched;
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
        return 1.0f - (bot.m_pEnemiesVisible.EnemiesVisible()*0.1f);
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
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer.pev.origin,W_FL_HEALTH,null,bot.m_fBelief);				

        if ( iWpt != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iWpt);

            sched.addTask(CFindHealthTask());

            return sched;
        }

        return null;
    }
}

class CWeaponGoalReached : RCBotTask
{
    CBotGetWeapon@ m_util;
    string DebugString ()
    {
        return "CWeaponGoalReached";
    }
    CWeaponGoalReached ( CBotGetWeapon@ util )
    {
        @m_util = util;
    }

    void execute ( RCBot@ bot ) 
    {
        m_util.goalReached();
        Complete();
    }
}

class CCheckoutNoiseUtil : CBotUtil
{
    string DebugMessage ()
    {
        return "CCheckoutNoiseUtil";
    }      
    float calculateUtility ( RCBot@ bot )
    {        
            return bot.totalHealth(); 
    }

    bool canDo (RCBot@ bot)
    {
        return bot.m_flHearNoiseTime + 10.0f > g_Engine.time;
    }    

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        Vector vOrigin = bot.m_pPlayer.pev.origin;

        int iRandomGoal = g_Waypoints.getNearestWaypointIndex(bot.m_vNoiseOrigin,null,-1,400.0,true,false);

        if ( iRandomGoal != -1 )
        {
            RCBotSchedule@ sched = RCBotSchedule();
            sched.addTask(CFindPathTask(bot,iRandomGoal));
            sched.addTask(CBotTaskWait(1.0f,bot.m_vNoiseOrigin));

            return sched;
        }

        return null;
    }        
}

class CBotGetWeapon : CBotUtil
{
    CFailedWaypointsList failed;
    int m_iLastGoal = -1;

    string DebugMessage ()
    {
        return "CBotGetWeapon";
    }

    void goalReached ()
    {
        if ( m_iLastGoal != -1 )
        {
            failed.remove(m_iLastGoal);
            m_iLastGoal = -1;
        }
    }

   float calculateUtility ( RCBot@ bot )
    {
        // TO DO calculate on bots current weapons collection
        float ret = 1.0 - bot.m_pWeapons.getNumWeaponsPercent(bot);
       
        return ret;
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        Vector vOrigin = bot.m_pPlayer.pev.origin;

        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(vOrigin,W_FL_WEAPON,failed,bot.m_fBelief);				
        
        m_iLastGoal = iWpt;

        if ( iWpt != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iWpt);

            sched.addTask(CFindWeaponTask());
            sched.addTask(CWeaponGoalReached(this));

            failed.add(m_iLastGoal);

            return sched;
        }
        else
            failed.clear();

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
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer.pev.origin,W_FL_AMMO,null,bot.m_fBelief);				

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
    string DebugString ()
    {
        return "CBotMoveToOrigin";
    }
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

class CBotGetArmorUtil : CBotUtil
{
    string DebugMessage ()
    {
        return "CBotGetArmorUtil";
    }  
   
    float calculateUtility ( RCBot@ bot )
    {
        float healthPercent = float(bot.m_pPlayer.pev.armorvalue) / bot.m_pPlayer.pev.armortype;

        return 0.75f*(1.0f - healthPercent);
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer.pev.origin,W_FL_ARMOR,null,bot.m_fBelief);				

        if ( iWpt != -1 )
        {
             RCBotSchedule@ sched = CFindPathSchedule(bot,iWpt);

             sched.addTask(CFindArmorTask());   

             return sched;
        }
        return null;
    }    
}


class CObjectiveReachedTask : RCBotTask
{
    CBotGotoObjectiveUtil@ m_util;
    string DebugString ()
    {
        return "CObjectiveReachedTask";
    }
    CObjectiveReachedTask ( CBotGotoObjectiveUtil@ util )
    {
        @m_util = util;
    }

    void execute (RCBot@bot )
    {
        m_util.completed();
        Complete();
    }
}


class OnPathFail
{
    void execute ()
    {

    }
}

final class CObjectivePathFail : OnPathFail
{
    CBotGotoObjectiveUtil@ m_util;

    CObjectivePathFail ( CBotGotoObjectiveUtil@ util )
    {
        @m_util = util;
    }

    void execute ()
    {
        m_util.completed();
    }
}

class CBotGotoObjectiveUtil : CBotUtil
{
    int m_iLastGoal = -1;

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
        // do not clear
        //failed.clear();
        m_fNextDo = 0;
    }

    void completed ()
    {
        if ( m_iLastGoal != -1 )
            failed.add(m_iLastGoal);

        m_iLastGoal = -1;
    }

    void setNextDo ()
    {
        m_fNextDo = g_Engine.time + 1.0f;
    }   

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iRandomGoal = -1;

        // use script if exists
        if ( g_WaypointScripts.ScriptExists() )
            iRandomGoal = g_Waypoints.getIncompleteObjective(bot.m_pPlayer);
        else
            iRandomGoal = g_Waypoints.getRandomFlaggedWaypoint(W_FL_IMPORTANT,failed,bot.m_fBelief);

        m_iLastGoal = iRandomGoal;

        if ( iRandomGoal != -1 )
        {
            CWaypoint@ pWpt = g_Waypoints.getWaypointAtIndex(iRandomGoal);

            RCBotSchedule@ sched = RCBotSchedule();

            CBaseEntity@ pSciBarn = null;

            if ( pWpt.hasFlags(W_FL_SCIENTIST) )
            {
                if ( !bot.IsScientistFollowing () )
                {
                    if ( bot.IsScientistNearby () )
                    {
                        CBaseEntity@ pScientist = bot.getNearestScientist();
                        //(bot.m_vLastSeeEnemy,null,-1,400.0,true,false);
                        int iWpt = g_Waypoints.getNearestWaypointIndex(UTIL_EntityOrigin(pScientist),null,-1,400.0,true,false);

                        if ( iWpt == -1 )
                        {
                            // no waypoint near scientist! :(
                            return null;
                        }

                        @pSciBarn = pScientist;
                        
                        //CFindPathTask ( RCBot@ bot, int wpt, CBaseEntity@ pEntity = null, OnPathFail@ onFail = null )
                        
                        sched.addTask(CFindPathTask(bot,iWpt,pScientist));
                        sched.addTask(CBotTaskUseNPC(pScientist));                        
                    }
                    else
                    {
                        // can't do this!!! maybe later...
                        return null;
                    }
                }                
            }
            else if ( pWpt.hasFlags(W_FL_BARNEY) )
            {
                if ( !bot.IsBarneyFollowing () )
                {
                    if ( bot.IsBarneyNearby () )
                    {
                        CBaseEntity@ pBarney = bot.getNearestBarney();

                        //(bot.m_vLastSeeEnemy,null,-1,400.0,true,false);
                        int iWpt = g_Waypoints.getNearestWaypointIndex(UTIL_EntityOrigin(pBarney),null,-1,400.0,true,false);

                        if ( iWpt == -1 )
                        {
                            // no waypoint near scientist! :(
                            return null;
                        }

                        @pSciBarn = pBarney;
                        
                        //CFindPathTask ( RCBot@ bot, int wpt, CBaseEntity@ pEntity = null, OnPathFail@ onFail = null )
                        
                        sched.addTask(CFindPathTask(bot,iWpt,pBarney));
                        sched.addTask(CBotTaskUseNPC(pBarney));     
                    }
                    else
                    {
                        // can't do this!!! maybe later...
                        return null;
                    }                    
                }           
            }

            // If path cannot be found, waypoint will be added to 'failed waypoints'
            sched.addTask(CFindPathTask(bot,iRandomGoal,null, CObjectivePathFail(this)));

            // similarly, If goal is reached, waypoint will be added to 'failed waypoints' so bot doesn't keep going back
            sched.addTask(CObjectiveReachedTask(this));
                    
            sched.addTask(CCheckObjectiveTask(iRandomGoal));

            bot.setObjectiveOrigin(pWpt.m_vOrigin);

            if ( pSciBarn !is null )
            {
//  CBotWaitForEntity ( Vector vOrigin, CBaseEntity@ pEntity, float fDist )
                sched.addTask(CBotWaitForEntity(pSciBarn,100.0f));
            }
          
            return sched;
        }
        else // all objective waypoints have been ticked off - clear all 'failed waypoints' just in case
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
            sched.addTask(CFindPathTask(bot,iRandomGoal,bot.m_pLastEnemy.GetEntity()));
            sched.addTask(CRemoveLastEnemy());
            sched.addTask(CBotTaskWait(1.0,UTIL_EntityOrigin(bot.m_pLastEnemy.GetEntity())));

            return sched;
        }

        return null;
    }
}

class CBotUseTankUtil : CBotUtil
{
    string DebugMessage ()
    {
        return "CBotUseTankUtil";
    }     

    float calculateUtility( RCBot@ bot )
    {
        // same as weapon
        return 1.0 - bot.m_pWeapons.getNumWeaponsPercent(bot);
    }

    bool canDo (RCBot@ bot)
    {
        if ( bot.m_pNearestTank.GetEntity() !is null )
            return CBotUtil::canDo(bot);

        return false;
    }  

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iRandomGoal = g_Waypoints.getNearestFlaggedWaypoint(UTIL_EntityOrigin(bot.m_pNearestTank.GetEntity()),W_FL_TANK,null,bot.m_fBelief);

        if ( iRandomGoal != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iRandomGoal);

            sched.addTask(CBotTaskUseTank(bot.m_pNearestTank.GetEntity()));

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
        int iRandomGoal = g_Waypoints.getRandomFlaggedWaypoint(W_FL_ENDLEVEL,failed,bot.m_fBelief);    

        if ( iRandomGoal != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iRandomGoal);

            CWaypoint@ pWpt = g_Waypoints.getWaypointAtIndex(iRandomGoal);

            bot.setObjectiveOrigin(pWpt.m_vOrigin);            

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
        return (0.0001f);
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

        // reset failed path
        bot.failedPath(false);
            
        return CFindPathSchedule(bot,iRandomGoal);
    }
}

class CBotUtilities 
{
    array <CBotUtil@>  m_Utils;
    RCBot@ m_pBot;
    float m_fNoUtilCanDoTime = 0;
    //int m_iNumUtilsChosen = 0;

    CBotUtilities ( RCBot@ bot )
    {
            @m_pBot = bot;
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
            m_Utils.insertLast(CBotUseTankUtil());
            m_Utils.insertLast(CCheckoutNoiseUtil());
            m_Utils.insertLast(CBotThrowGrenadeUtil());
            m_Utils.insertLast(CBotFindCoverUtil());
    }

    void reset ()
    {
        for ( uint i = 0; i < m_Utils.length(); i ++ )
        {
             m_Utils[i].reset();                        
             //m_Utils[i].calculateWeight(m_pBot,m_iNumUtilsChosen);
        }

        //m_iNumUtilsChosen = 0;
    
    }

    RCBotSchedule@  execute ( RCBot@ bot )
    {
        array <CBotUtil@>  UtilsCanDo;

        for ( uint i = 0; i < m_Utils.length(); i ++ )
        {
            CBotUtil@ util = m_Utils[i];

            if ( util.canDo(bot) )
            {                                   
                //util.setUtility(util.calculateUtility(bot)*util.getWeight());
                util.setUtility(util.calculateUtility(bot));
               // UTIL_DebugMsg(bot.m_pPlayer,"Utility = " + m_Utils[i].utility);
                UtilsCanDo.insertLast(util);
            }
        }

        if ( UtilsCanDo.length() > 0 )
        {
            UtilsCanDo.sort(function(a,b) { return a.utility > b.utility; });

            m_fNoUtilCanDoTime = 0;
            for ( uint i = 0; i < UtilsCanDo.length(); i ++ )
            {
                CBotUtil@ chosenUtil = UtilsCanDo[i];
                RCBotSchedule@ sched = chosenUtil.execute(bot);

                if ( sched !is null )
                {     
                    //chosenUtil.chosen();     
                    //m_iNumUtilsChosen++;          
                    UTIL_DebugMsg(bot.m_pPlayer,"Chosen Utility = " + chosenUtil.DebugMessage() + " Value = " + chosenUtil.utility, DEBUG_UTIL );
                    chosenUtil.setNextDo();

                    return sched;
                }
            }

        }
        else
        {
            reset();

            if ( m_fNoUtilCanDoTime == 0 )
                m_fNoUtilCanDoTime = g_Engine.time + 10;
            else if ( m_fNoUtilCanDoTime < g_Engine.time )
            {
                // ten seconds passed, still no util, suicide
                bot.m_pPlayer.Killed(bot.m_pPlayer.pev, 0);
                m_fNoUtilCanDoTime = 0;
            }
        }

        return null;
    }
}