
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
    CFindPathSchedule ( RCBot@ bot )
    {
        addTask(CFindPathTask(bot,Math.RandomLong(0,g_Waypoints.m_iNumWaypoints-1)));
    }
}