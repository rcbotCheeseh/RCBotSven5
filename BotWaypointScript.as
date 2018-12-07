#include "BotWaypoint"

BotWaypointScript g_WaypointScripts;

enum ScriptOperator
{
    Equals,
    LessThan,
    GreaterThan    
}

bool CheckScriptOperator ( float check, ScriptOperator op, float value )
{
    bool ret = false;

    

    switch ( op )
    {
        case Equals:
        ret = (check == value);
       // BotMessage("CheckScriptOperator " + check + "==" + value);
        break;
        case LessThan:
        ret = (check < value);
       // BotMessage("CheckScriptOperator " + check + "<" + value);
        break;
        case GreaterThan:
        ret = (check > value);
       // BotMessage("CheckScriptOperator " + check + ">" + value);
        break;
        default:
        break;
    }

   // BotMessage("CheckScriptOperator result is " + (ret ? "TRUE" : "FALSE") );

    return ret;
}

// Example
//#WID, prev, entity search, parameter, operator, value
//[0],   [1],           [2],      [3],      [4],    [5]
//12,    -1,    env_sprite,  distance,        >,   100
//32,    12,          null,  	   null,     null,  null 
BotObjectiveScript@ ObjectiveScriptRead ( string line )
{

    // comma separated
    array<string> args = line.Split( "," );

    if ( args.length() != 6 )
        return null;

    for ( uint i = 0; i < args.length() ; i ++ )
    {
        args[i].Trim();
    }

    int id = atoi(args[0]);
    int prev = atoi(args[1]);
    int ent = atoi(args[2]);
    string param = args[3];
    string op = args[4];    

    ScriptOperator sop;

    if ( op == ">" )
        sop = GreaterThan;
    else if ( op == "<" )
        sop = LessThan;
    else
        sop = Equals;

    float value = atof(args[5]);

    return BotObjectiveScript ( id, prev,
     ent, param, sop, value );
}

class BotObjectiveScript
{
    int id;
    int previous_id;
    int entity_id;
    string parameter;
    ScriptOperator operator;
    float value;

    BotObjectiveScript ( int wptid, int prev_id,
     int ent_id, string param, ScriptOperator op, float val )
    {
        id = wptid;
        previous_id = prev_id;
        entity_id = ent_id;
        parameter = param;
        operator = op;
        value = val;
    }    

    bool isForWaypoint ( int wptid )
    {
        return id == wptid;
    }
}

enum BotWaypointScriptResult
{
    BotWaypointScriptResult_Error,
    BotWaypointScriptResult_Previous_Incomplete,
    BotWaypointScriptResult_Incomplete,
    BotWaypointScriptResult_Complete
}

class BotWaypointScript
{
    array<BotObjectiveScript@> m_scripts;

    bool ScriptExists ()
    {
        return m_scripts.length() > 0;
    }

    void Read ()
    {
        string filename = "" + g_Engine.mapname + ".ini";
        File@ f;
        
        m_scripts = { };

        @f = g_FileSystem.OpenFile( "scripts/plugins/store/" + filename , OpenFile::READ);

        if ( f is null )
            @f = g_FileSystem.OpenFile( "scripts/plugins/BotManager/rcw/" + filename , OpenFile::READ);

        // Open the file in 'read' mode
		if( f !is null ) 
		{
            while ( !f.EOFReached() )
			{
				string fileLine; 
                
                f.ReadLine( fileLine );

                if ( fileLine[0] == "#" )
					continue;

                BotObjectiveScript@ script = ObjectiveScriptRead(fileLine);

                if ( script !is null )
                {                    
                    m_scripts.insertLast(script);
                }
            }

            f.Close();
        }
    }

    BotWaypointScriptResult canDoObjective ( int wptid )
    {
        BotObjectiveScript@ script = getScript(wptid);
        CWaypoint@ pWpt;

        if ( script is null )
        {
            //BotMessage("SCRIPT no script found for wpt id " + wptid);
            return BotWaypointScriptResult_Error;
        }

        if ( script.previous_id >= 0 )
        {
            if ( canDoObjective(script.previous_id) != BotWaypointScriptResult_Complete )
            {
               // BotMessage("SCRIPT isObjectiveComplete(script.previous_id) != BotWaypointScriptResult_Complete" );
                return BotWaypointScriptResult_Previous_Incomplete;
            }
        }

        @pWpt = g_Waypoints.getWaypointAtIndex(wptid);

        if ( pWpt is null )
        {
           // BotMessage("SCRIPT pWpt is null, BotWaypointScriptResult_Error");
            return BotWaypointScriptResult_Error;
        }

        Vector vOrigin = pWpt.m_vOrigin;

        if ( script.entity_id != -1 )
        {
            edict_t@ edict = g_EntityFuncs.IndexEnt(script.entity_id);
            CBaseEntity@ pent = null;

            if ( edict !is null )
            {
                if ( edict.free == 0 )
                {
                    @pent = g_EntityFuncs.Instance(edict);
                }
            }

            if ( pent is null )
            {
                if ( script.parameter == "null" )
                {
                   // BotMessage("SCRIPT script.parameter == 'null' BotWaypointScriptResult_Complete");
                    return BotWaypointScriptResult_Complete;
                }

               // BotMessage("SCRIPT pent is null BotWaypointScriptResult_Incomplete");
                return BotWaypointScriptResult_Incomplete;
            }

            if ( script.parameter == "distance" )
            {
                float distance = (UTIL_EntityOrigin(pent) - vOrigin).Length();

                if ( CheckScriptOperator(distance,script.operator,script.value) )
                    return BotWaypointScriptResult_Complete;
            }
            else if ( script.parameter == "frame" )
            {
                if ( CheckScriptOperator(pent.pev.frame,script.operator,script.value) )
                    return BotWaypointScriptResult_Complete;
            }
            else if ( script.parameter == "x" )
            {
                Vector pentOrigin = UTIL_EntityOrigin(pent);

                if ( CheckScriptOperator(pentOrigin.x,script.operator,script.value) )
                    return BotWaypointScriptResult_Complete;
            }
            else if ( script.parameter == "y" )
            {
                Vector pentOrigin = UTIL_EntityOrigin(pent);

                if ( CheckScriptOperator(pentOrigin.y,script.operator,script.value) )
                    return BotWaypointScriptResult_Complete;
            }
            else if ( script.parameter == "z" )
            {
                Vector pentOrigin = UTIL_EntityOrigin(pent);

                if ( CheckScriptOperator(pentOrigin.z,script.operator,script.value) )
                    return BotWaypointScriptResult_Complete;
            }                        
        }        

        return BotWaypointScriptResult_Incomplete;
    }

    BotObjectiveScript@ getScript ( int wptid )
    {
        for ( uint i = 0; i < m_scripts.length(); i ++ )
        {
            BotObjectiveScript@ scr = m_scripts[i];

            if ( scr.isForWaypoint(wptid) )
            {
                return scr;
            }
        }

        return null;
    }
}