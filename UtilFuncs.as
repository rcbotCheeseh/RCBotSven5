
	float  UTIL_FixFloatAngle ( float fAngle )
	{
		int iLoops; // safety

		iLoops = 0;

		if ( fAngle < -180 )
		{
			while ( (iLoops < 4) && (fAngle < -180) )
			{
				fAngle += 360.0;
				iLoops++;
			}
		}
		else if ( fAngle > 180 )
		{
			while ( (iLoops < 4) && (fAngle > 180) )
			{
				fAngle -= 360.0;
				iLoops++;
			}
		}

		if ( iLoops >= 4 )
			fAngle = 0; // reset

			return fAngle;
	}

	Vector UTIL_EntityOrigin ( CBaseEntity@ entity )
	{

	if ( entity.pev.flags & FL_MONSTER == FL_MONSTER )
		return entity.pev.origin + (entity.pev.view_ofs/2);

	return entity.pev.absmin + (entity.pev.size / 2);

	//return pEdict->v.origin;

	}
    
    void BotMessage ( string message )
    {
		if ( g_DebugOn == true )
        	g_Game.AlertMessage( at_console, "[RCBOT]" + message + "\n" );	
    }

	void SayMessage ( CBasePlayer@ player, string message )
	{
		g_PlayerFuncs.SayText(player, "[RCBOT]" + message + "\n" );
	}

	void SayMessageAll ( CBasePlayer@ player, string message )
	{
		g_PlayerFuncs.SayTextAll(player, "[RCBOT]" + message + "\n" );	
	}

    void UTIL_PrintVector ( string name, Vector v )
    {
		if ( g_DebugOn == true )
        	g_Game.AlertMessage( at_console, name + " = (" + v.x + "," + v.y + "," + v.z + ")\n" );	
    }

	float UTIL_DotProduct ( Vector vA, Vector vB )
	{
		return ( (vA.x * vB.x) + (vA.y + vB.y) + (vA.z * vB.z) );
	}

	float UTIL_yawAngleFromEdict ( Vector vOrigin, Vector vBotAngles, Vector vBotOrigin)
	{
		float fAngle;

        //UTIL_PrintVector("vOrigin" , vOrigin);   

        Vector vComp = vBotOrigin - vOrigin;
        Vector vAngles;

        vAngles = Math.VecToAngles(vComp);

       // UTIL_PrintVector("vAngles" , vAngles);        
		
		fAngle = vBotAngles.y - vAngles.y;

        fAngle += 180;

		fAngle = UTIL_FixFloatAngle(fAngle);

		return fAngle;

	}

	void UTIL_DebugMsg ( CBasePlayer@ debugBot, int level, string message )
	{
		/*if ( g_DebugBot == debugBot )
		{
			if ( g_DebugLevel & level == level )
			{
				BotMessage("DEBUG: " + message);
			}*
		}*/
	}

    bool UTIL_IsVisible ( Vector vFrom, Vector vTo, CBaseEntity@ ignore = null )
    {
        TraceResult tr;

//void TraceHull(const Vector& in vecStart, const Vector& in vecEnd, IGNORE_MONSTERS igmon,HULL_NUMBER hullNumber, edict_t@ pEntIgnore, TraceResult& out ptr)

        g_Utility.TraceLine( vFrom, vTo, ignore_monsters,dont_ignore_glass, ignore is null ? null : ignore.edict(), tr );

        return tr.flFraction >= 1.0f;
    }   
		
    bool UTIL_IsVisible ( Vector vFrom, CBaseEntity@ pTo, CBaseEntity@ ignore )
    {
        TraceResult tr;

		Vector vTo = UTIL_EntityOrigin(pTo);

        g_Utility.TraceLine( vFrom, vTo, ignore_monsters, dont_ignore_glass , ignore !is null ? null : ignore.edict(), tr );

        CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

        return tr.flFraction >= 1.0f || (pTo is pEntity);
    }   
		        