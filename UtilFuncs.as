
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

    
    void BotMessage ( string message )
    {
        g_Game.AlertMessage( at_console, "[RCBOT]" + message );	
    }


    void UTIL_PrintVector ( string name, Vector v )
    {
        g_Game.AlertMessage( at_console, name + " = (" + v.x + "," + v.y + "," + v.z + ")\n" );	
    }

	float UTIL_yawAngleFromEdict ( Vector vOrigin, Vector vBotAngles, Vector vBotOrigin)
	{
		float fAngle;

         UTIL_PrintVector("vOrigin" , vOrigin);   

        Vector vComp = vBotOrigin - vOrigin;
        Vector vAngles;

        vAngles = Math.VecToAngles(vComp);

        UTIL_PrintVector("vAngles" , vAngles);        
		
		fAngle = vBotAngles.y - vAngles.y;

        fAngle += 180;

		fAngle = UTIL_FixFloatAngle(fAngle);

		return fAngle;

	}

    bool UTIL_IsVisible ( Vector vFrom, Vector vTo, CBaseEntity@ ignore )
    {
        TraceResult tr;

//void TraceHull(const Vector& in vecStart, const Vector& in vecEnd, IGNORE_MONSTERS igmon,HULL_NUMBER hullNumber, edict_t@ pEntIgnore, TraceResult& out ptr)

        g_Utility.TraceLine( vFrom, vTo, ignore_monsters,dont_ignore_glass, ignore !is null ? null : ignore.edict(), tr );

        return tr.flFraction >= 1.0f;
    }   
		
    bool UTIL_IsVisible ( Vector vFrom, CBaseEntity@ pTo, CBaseEntity@ ignore )
    {
        TraceResult tr;

        g_Utility.TraceLine( vFrom, pTo.pev.origin, ignore_monsters, dont_ignore_glass , ignore !is null ? null : ignore.edict(), tr );

        CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

        return tr.flFraction >= 1.0f || pTo == pEntity;
    }   
		        