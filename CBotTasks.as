
// ------------------------------------
// TASKS / SCHEDULES - 	START
// ------------------------------------
class RCBotTask
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
		m_pTasks.insertAt(0,pTask);
	}

	void addTask ( RCBotTask@ pTask )
	{	
		m_pTasks.insertLast(pTask);
	}

	bool execute (RCBot@ bot)
	{        
        RCBotTask@ m_pCurrentTask = m_pTasks[m_iCurrentTaskIndex];

        m_pCurrentTask.execute(bot);
        
        if ( m_pCurrentTask.m_bComplete )
        {                
            m_iCurrentTaskIndex ++;

            if ( m_iCurrentTaskIndex >= m_pTasks.length() )
                return true;
        }
        else if ( m_pCurrentTask.m_bFailed )
        {
            return true;
        }

        return false;
	}
}

// ------------------------------------
// TASKS / SCHEDULES - 	END
// ------------------------------------

final class CFindPathTask : RCBotTask
{
    CFindPathTask ( RCBot@ bot, int wpt )
    {
        @bot.navigator = RCBotNavigator(bot,wpt);
    }

    CFindPathTask ( RCBot@ bot, Vector origin )
    {
        @bot.navigator = RCBotNavigator(bot,origin);
    }
/*
}
	const int NavigatorState_Complete = 0;
	const int NavigatorState_InProgress = 1;
	const int NavigatorState_Fail = 2;
*/
    void execute ( RCBot@ bot )
    {
        switch ( bot.navigator.run() )
        {
        case NavigatorState_Complete:
            // follow waypoint
            
        break;
        case NavigatorState_InProgress:
            // waiting...
        break;
        case NavigatorState_Fail:
            Failed();
        break;
        case NavigatorState_ReachedGoal:
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

/// UTIL

abstract class CBotUtil
{
    float utility;

    CBotUtil ( float util ) { utility = util; }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        return null;
    }
}

class CBotGetHealthUtil : CBotUtil
{
    CBotGetHealthUtil ( RCBot@ bot )
    {
        float healthPercent = float(bot.m_pPlayer.pev.health) / bot.m_pPlayer.pev.max_health;

        super(1.0f - healthPercent);
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer,W_FL_HEALTH);				

        if ( iWpt != -1 )
            return CFindPathSchedule(bot,iWpt);

        return null;
    }
}

class CBotGetArmorUtil : CBotUtil
{
    CBotGetArmorUtil ( RCBot@ bot )
    {
        float healthPercent = float(bot.m_pPlayer.pev.armorvalue) / 100;

        super(1.0f - healthPercent);
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer,W_FL_ARMOR);				

        if ( iWpt != -1 )
            return CFindPathSchedule(bot,iWpt);

        return null;
    }    
}

class CBotRoamUtil : CBotUtil
{
    CBotRoamUtil( RCBot@ bot )
    {
        super(0.1f);
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iRandomGoal = g_Waypoints.getRandomFlaggedWaypoint(W_FL_ENDLEVEL);

        if ( iRandomGoal == -1 )
            iRandomGoal = g_Waypoints.getRandomFlaggedWaypoint(W_FL_IMPORTANT);
        
        if ( iRandomGoal != -1 )
        {
            return CFindPathSchedule(bot,iRandomGoal);
        }

        return null;
    }
}

class CBotUtilities 
{
    array <CBotUtil@>  m_Utils;

    CBotUtilities ( RCBot@ bot )
    {
            //m_Utils.insertLast(CBotGetHealthUtil(bot));
            //m_Utils.insertLast(CBotGetArmorUtil(bot));
            m_Utils.insertLast(CBotRoamUtil(bot));

            m_Utils.sort(function(a,b) { return a.utility > b.utility; });
    }

    RCBotSchedule@  execute ( RCBot@ bot )
    {
        for ( uint i = 0; i < m_Utils.length(); i ++ )
        {
            RCBotSchedule@ sched = m_Utils[i].execute(bot);

            if ( sched !is null )
            {
                BotMessage("GOT A NEW SCHEDULE");
                return sched;
            }
        }

        return null;
    }
}