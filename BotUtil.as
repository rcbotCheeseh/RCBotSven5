abstract class CBotUtil
{
    float utility;

    CBotUtil ( float util ) { utility = util; }

    bool execute ( RCBot@ bot );    
}

class CBotRoamUtil : CBotUtil
{
    CBotRoamUtil( RCBot@ bot )
    {
        super(0.1f);
    }

    bool execute ( RCBot@ bot )
    {
        int iRandomGoal = g_Waypoints.getRandomFlaggedWaypoint(W_FL_ENDLEVEL);

        if ( iRandomGoal == -1 )
            iRandomGoal = g_Waypoints.getRandomFlaggedWaypoint(W_FL_OBJECTIVE);
        
        if ( iRandomGoal != -1 )
        {

            return true;
        }

        return false;
    }
}