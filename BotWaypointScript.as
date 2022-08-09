#include "BotWaypoint"

BotWaypointScript g_WaypointScripts;

enum ScriptOperator
{
    Equals,
    LessThan,
    GreaterThan,
    NotEqual 
}

bool CheckScriptOperator ( float check, ScriptOperator op, float value )
{
    bool ret = false;

    

    switch ( op )
    {
        case Equals:
        ret = (check == value);
        //BotMessage("CheckScriptOperator " + check + "==" + value);
        break;
        case LessThan:
        ret = (check < value);
        //BotMessage("CheckScriptOperator " + check + "<" + value);
        break;
        case GreaterThan:
        ret = (check > value);
        //BotMessage("CheckScriptOperator " + check + ">" + value);
        break;
        case NotEqual:
        ret = (check != value);
        //BotMessage("CheckScriptOperator " + check "!=" + value);
        default:
        break;
    }

    //BotMessage("CheckScriptOperator result is " + (ret ? "TRUE" : "FALSE") );

    return ret;
}
/*
abstract class BotObjectiveFlag 
{
    string m_name;

    BotObjectiveFlag ( string name )
    {
        m_name = name;
    }

    bool isName ( string name )
    {
        return m_name == name;
    }

    bool CanDo ( CBaseEntity@ bot )
    {
        return false;
    }
}

final class BotObjectiveFlag_NeedFullHealth : BotObjectiveFlag
{
    BotObjectiveFlag_NeedFullHealth ()
    {
        super("need_full_health");
    }

    bool CanDo ( CBaseEntity@ bot )
    {
        return bot.pev.health >= 100.0;
    }
}

final class BotObjectiveFlag_NeedFullArmor : BotObjectiveFlag
{
    BotObjectiveFlag_NeedFullArmor ()
    {
        super("need_full_armor");
    }

    bool CanDo ( CBaseEntity@ bot )
    {
        return bot.pev.armorvalue >= 100.0;
    }
}

class BotObjectiveFlags
{
    array<BotObjectiveFlag@> m_flags;

    BotObjectiveFlags()
    {
        m_flags = {};
    }

    void addFlag ( BotObjectiveFlag@ flag )
    {
        m_flags.push_back(flag);
    }

    bool CanDo ( CBaseEntity@ bot )
    {
        for ( uint i = 0; i < m_flags.length() ; i ++ )
        {
            if ( m_flags[i].CanDo(bot) == false )
                return false;
        }

        return true;
    }
};


final class BotObjectiveFlagManager : BotObjectiveFlags
{
    BotObjectiveFlagManager()
    {
        addFlag(BotObjectiveFlag_NeedFullHealth());
        addFlag(BotObjectiveFlag_NeedFullArmor());
    }

    BotObjectiveFlag@ getFlag ( string name )
    {
        for ( uint i = 0; i < m_flags.length() ; i ++ )
        {
            if ( m_flags[i].isName(name) )
                return m_flags[i];
        }

        return null;
    }

    void Parse ( string flags, BotObjectiveFlags@ flags_object )
    {
        array<string> flags_split = flags.Split("|");

        for ( uint i = 0; i < flags_split.length() ; i ++ )
        {
           BotObjectiveFlag@ flag_object = getFlag(flags_split[i]);

           if ( flags_object !is null )
                flags_object.addFlag(flag_object);
        }
    }

};

BotObjectiveFlagManager m_BotObjectiveFlagManager = BotObjectiveFlagManager();
*/

// Example
//#WID, prev, entity search, parameter, operator, value, extra_flags
//[0],   [1],           [2],      [3],      [4],    [5],  [6]
//12,    -1,    env_sprite,  distance,        >,   100,   need_armor|need_health
//32,    12,          null,  	   null,     null,  null,  null
BotObjectiveScript@ ObjectiveScriptRead ( string line )
{

    // comma separated
    array<string> args = line.Split( "," );

    if ( args.length() < 6 )
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

   // string flags = "";
    
    /*if ( args.length() > 6 )
        flags = args[6];*/

    ScriptOperator sop;

    if ( op == ">" )
        sop = GreaterThan;
    else if ( op == "<" )
        sop = LessThan;
    else if ( op == "=" )
        sop = Equals;
    else if ( op == "!=" )
        sop = NotEqual;
    else if ( op == "null" )
        sop = Equals;
    else
        return null; // Invalid operation

    float value = atof(args[5]);

    return BotObjectiveScript ( id, prev,
     ent, param, sop, value/*, flags*/ );
}

class BotObjectiveScript
{
    int id;
    int previous_id;
    int entity_id;
    string parameter;
    ScriptOperator operator;
    float value;
    EHandle entity;
    //BotObjectiveFlags@ m_flags;

    BotObjectiveScript ( int wptid, int prev_id,
     int ent_id, string param, ScriptOperator op, float val/*, string flags*/ )
    {

        id = wptid;
        previous_id = prev_id;
        // entity ID is the script value take away 8
        // all entity IDs must be taken when maxplayers is 8 (default)
        // then maxClients is added on (so if it is 8 there is no change)
        // script Entity offset is used for dedicated servers
        entity_id = ent_id + g_ScriptEntityOffset - 8 + g_Engine.maxClients;

        parameter = param;
        operator = op;
        value = val;
        
        entity = null;

       // @m_flags = BotObjectiveFlags();

       // m_BotObjectiveFlagManager.Parse(flags,m_flags);

        initEntity();
    }    

    bool isForWaypoint ( int wptid )
    {
        return id == wptid;
    }

    void initEntity ()
    {
        if ( entity_id >= 0 && entity_id < g_Engine.maxEntities )
        {
            edict_t@ edict = g_EntityFuncs.IndexEnt(entity_id);
            
            if ( edict !is null )
            {
                entity = g_EntityFuncs.Instance(edict);                
            }

            if ( entity.GetEntity() is null )
                BotMessage("SCRIPT ENTITY " + entity_id + " NOT FOUND" );
        }    
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
                else
                {
                    BotMessage("ERROR Reading waypoint script line '"+fileLine+"'");
                }
            }

            f.Close();
        }
    }

    BotWaypointScriptResult canDoObjective ( CBaseEntity@ pBot, int wptid )
    {
        BotObjectiveScript@ script = getScript(wptid);
        CWaypoint@ pWpt;

        if ( script is null )
        {
            //BotMessage("SCRIPT no script found for wpt id " + wptid);
            return BotWaypointScriptResult_Error;
        }

        //if ( script.m_flags.CanDo(pBot) == false )
        //    return BotWaypointScriptResult_Error; // need pre-requisite

        if ( script.previous_id >= 0 )
        {
            if ( canDoObjective(pBot,script.previous_id) != BotWaypointScriptResult_Complete )
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

         if ( script.entity_id == 0 ) // self
         {
             CBaseEntity@ pent = pBot;

              if ( script.parameter == "health" )
              {
                if ( CheckScriptOperator(pent.pev.health,script.operator,script.value) )
                    return BotWaypointScriptResult_Complete;
              }
              else if ( script.parameter == "armor" )
              {
                if ( CheckScriptOperator(pent.pev.armorvalue,script.operator,script.value) )
                    return BotWaypointScriptResult_Complete;
              }
         }
        else if ( script.entity_id > 0 )
        {
            CBaseEntity@ pent = script.entity.GetEntity();
     
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

            //BotMessage("ID: " + wptid + " " + script.parameter);

            if ( script.parameter == "active" )
            {
                float isActive = UTIL_ToggleIsActive(pent,pBot) ? 1.0 : 0.0;

                BotMessage("isActive == " + isActive);
                
                if ( CheckScriptOperator(isActive,script.operator,script.value) )
                    return BotWaypointScriptResult_Complete;
            }
            else if ( script.parameter == "distance" )
            {
                float distance = (UTIL_EntityOrigin(pent) - vOrigin).Length();

                if ( CheckScriptOperator(distance,script.operator,script.value) )
                    return BotWaypointScriptResult_Complete;
            }
            else if ( script.parameter == "frame" )
            {
               // BotMessage("CHECKING FRAME");
                if ( CheckScriptOperator(pent.pev.frame,script.operator,script.value) )
                {
                   // BotMessage("OK!");
                    return BotWaypointScriptResult_Complete;
                }
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
            else if ( script.parameter == "angle.x" )
            {
                if ( CheckScriptOperator(pent.pev.angles.x,script.operator,script.value) )
                    return BotWaypointScriptResult_Complete;
            }  
            else if ( script.parameter == "angle.y" )
            {
                if ( CheckScriptOperator(pent.pev.angles.y,script.operator,script.value) )
                    return BotWaypointScriptResult_Complete;
            }    
            else if ( script.parameter == "solid" )
            {
                if ( CheckScriptOperator(pent.pev.solid,script.operator,script.value) )
                    return BotWaypointScriptResult_Complete;
            }                                           
            else if ( script.parameter == "visible" )
            {
                float isVisible = 1;
                
                if ( pent.pev.effects & EF_NODRAW == EF_NODRAW )
                    isVisible = 0;                

                if ( CheckScriptOperator(isVisible,script.operator,script.value) )
                {
                   // BotMessage("VISIBLE CHECK OK");
                    return BotWaypointScriptResult_Complete;
                }
                //else
               // BotMessage("VISIBLE CHECK FAIL");
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