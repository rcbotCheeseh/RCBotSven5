#include "UtilFuncs"
#include "BotCommands"
#include "BotProfile"
/*
*	This file defines the interface to the bot manager
*	This is a sample script.
*/

bool g_WaypointsLoaded = false;
bool g_MapInit = false;

enum eCamLookState
{
	BOTCAM_NONE = 0,
	BOTCAM_BOT,
	BOTCAM_ENEMY,
	BOTCAM_WAYPOINT,
	BOTCAM_FP
}
// one bot cam, other players can tune into it
class CBotCam
{

	CBotCam ()
	{
		Clear(false);	
	}

	void Spawn ()
	{
		if ( m_bTriedToSpawn )
			return;

		m_bTriedToSpawn = true;

		// Redfox http://www.foxbot.net
		@m_pCameraEdict = g_EntityFuncs.CreateEntity("info_target",null,false);
		// /Redfox

		if ( m_pCameraEdict is null )
			return;
		
		if ( !FNullEnt(m_pCameraEdict.edict()) )
		{
			// Redfox http://www.foxbot.net
			g_EntityFuncs.DispatchSpawn(m_pCameraEdict.edict());
			
			g_EntityFuncs.SetModel(m_pCameraEdict, "models/mechgibs.mdl");

			m_pCameraEdict.pev.takedamage = DAMAGE_NO;
			m_pCameraEdict.pev.solid = SOLID_NOT;
			m_pCameraEdict.pev.movetype = MOVETYPE_FLY; //noclip
			//m_pCameraEdict.pev.classname = string_t("entity_botcam");
			m_pCameraEdict.pev.nextthink = g_Engine.time;
			m_pCameraEdict.pev.renderamt = 0;
			// /Redfox
		}		
	}

	void Think ()
	{
		if ( m_bTriedToSpawn == false )
		{
			//BotMessage("m_bTriedToSpawn == false ");
			return;
		}
		
		if ( m_fNextChangeBotTime < g_Engine.time )
		{
			m_fNextChangeBotTime = g_Engine.time + 5.0f;

			@m_pCurrentBot = g_BotManager.getBestBot();

			/*if ( m_pCurrentBot !is null )
			{
				// Best bot is 
				//BotMessage("BOTCAM, Best bot is " + m_pCurrentBot.m_pPlayer.pev.netname);
			}*/
		}

		UpdateCamera();
	}


	/*eCamLookState chooseState ()
	{

	}*/

	void UpdateCamera ()
	{
		if ( m_pCurrentBot !is null )
		{
			Vector vLookAt;
			CBaseEntity@ pEntityFrom;

			if ( m_pCameraEdict is null )
			{
				//BotMessage("m_pCameraEdict is null ");
				return;
			}

			CBasePlayer@ pPlayer = m_pCurrentBot.m_pPlayer;
			// Ok set noise to forward vector
			g_EngineFuncs.MakeVectors(pPlayer.pev.v_angle);
			Vector vOrigin = pPlayer.EyePosition() - (g_Engine.v_forward * 128.0f);
			vOrigin.z = pPlayer.EyePosition().z;
			Vector vAngles = Math.VecToAngles(pPlayer.EyePosition() - vOrigin);

			TraceResult tr;

		   g_Utility.TraceLine( pPlayer.EyePosition(), vOrigin, ignore_monsters,dont_ignore_glass, m_pCurrentBot.m_pPlayer.edict(), tr );

			m_pCameraEdict.SetOrigin(tr.vecEndPos);
			m_pCameraEdict.pev.v_angle = vAngles;
			m_pCameraEdict.pev.angles = vAngles;
			
		}
	}

	void Clear (bool precached)
	{
		@m_pCurrentBot = null;
		m_iState = BOTCAM_NONE;
		@m_pCameraEdict = null;
		m_fNextChangeBotTime = 0;
		m_fNextChangeState = 0;
		m_bTriedToSpawn = !precached;				
	}

	bool TuneIn ( CBasePlayer@ pPlayer )
	{
		Spawn();
		
		if ( m_pCameraEdict is null )
		{			
			BotMessage("Camera Edict is null");
			return false;
		}

		g_EngineFuncs.SetView(pPlayer.edict(),m_pCameraEdict.edict());

		return true;
	}

	void TuneOff ( CBasePlayer@ pPlayer )
	{
		g_EngineFuncs.SetView(pPlayer.edict(),pPlayer.edict());
	}

	bool IsWorking ()
	{
		return (m_pCameraEdict !is null);
	}

	bool BotHasEnemy ()
	{
		if ( m_pCurrentBot is null)
			return false;

		return (m_pCurrentBot.m_pEnemy.GetEntity() !is null);
	}


	void SetCurrentBot(RCBot@ pBot)
	{
		@m_pCurrentBot = pBot;
		m_fNextChangeBotTime = g_Engine.time + Math.RandomFloat(5.0,7.5);
		m_fNextChangeState = g_Engine.time;
	}

	RCBot@ m_pCurrentBot;
	eCamLookState m_iState;
	CBaseEntity@ m_pCameraEdict;
	float m_fNextChangeBotTime;
	float m_fNextChangeState;
	bool m_bTriedToSpawn;
	//float m_fThinkTime;
	TraceResult tr;
	int m_iPositionSet;
	Vector vBotOrigin;

	//HudText m_Hudtext;
	//BOOL m_TunedIn[MAX_PLAYERS];
}

CBotCam g_BotCam;

namespace BotManager
{

	/*
	*	Base class for bots.
	*/
	abstract class BaseBot
	{
		/** player handle to bot */
		CBasePlayer@ m_pPlayer;
		/** milliseconds between each runPlayerMove */
		private int m_iMSecInterval = 0;
		/* last time runPlayerMove was called */
		private float m_flLastRunMove = 0;
		/* Bot profile handle which contains bots name, model etc */
		BotProfile@ m_pProfile;
		/** calls to moveTo() will be ignored if priority is lower */
		int m_iMovePriority = 0;
		/** calls to lookAt() will be ignored if priority is lower */
		int m_iLookPriority = 0;
		/** current look/move priority */
		int m_iCurrentPriority = 0;
		/** Current vector moving towards */
		Vector m_vMoveTo;
		/** if false , bot will stay still */
		bool m_bMoveToValid;

		Vector m_vLookAt;

		bool m_vLookAtIsValid;
				
		float m_fUpMove;
		float m_fSideMove;
		float m_fForwardMove;		
		float m_fDesiredMoveSpeed = 0;
		bool m_bCeaseFire = false;

		bool m_bIsAvoiding = false;
		Vector m_vAvoidVector;

		// nothing
		void hurt ( DamageInfo@ damageInfo )
		{

		}

		/** bot releases pressed buttons */
		void ReleaseButtons ( )
		{
			m_pPlayer.pev.button = 0;
		}
		/** press a key */
		void PressButton ( int button )
		{
			m_pPlayer.pev.button |= button;
		}

		void setMove ( Vector origin )
		{			
			if ( m_iCurrentPriority >= m_iMovePriority )
			{
				m_vMoveTo = origin;
				m_bMoveToValid = true;
				//BotMessage("setMove !");
			}
			//BotMessage("setMove IGNORE");
		}
		/** @return true if bot is on a ladder */
		bool IsOnLadder ( ) 
		{ 
			return (m_pPlayer.pev.movetype == MOVETYPE_FLY);
		}	
		/** forces bot to look at vector */
		void setLookAt ( Vector origin, int priority = 0 )
		{
			if ( (m_iCurrentPriority > m_iLookPriority) || (priority > m_iLookPriority) )
			{
				m_vLookAtIsValid = true;
				m_vLookAt = origin;

				if ( priority > m_iCurrentPriority )
					m_iLookPriority = priority;
				else 
					m_iLookPriority = m_iCurrentPriority;

				UTIL_DebugMsg(m_pPlayer,"Vector beginning x = " + m_vLookAt.x + " LOOK AT priority is : " + priority,DEBUG_LOOK);
			}
		}

		void ceaseFire ( bool cease )
		{
			m_bCeaseFire = cease;
		}

		bool ceasedFiring ()
		{
			return m_bCeaseFire;
		}

		void setAvoiding ( bool bIsAvoiding )
		{
			m_bIsAvoiding = bIsAvoiding;
		}

		void setAvoidVector ( Vector vAvoidVector )
		{
			m_vAvoidVector = vAvoidVector;
		}
		
		CBasePlayer@ Player
		{
			get const { return m_pPlayer; }
		}
		
		BaseBot( CBasePlayer@ pPlayer )
		{
			@m_pPlayer = pPlayer;
		}
		
		void Spawn()
		{
			m_pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;

			m_vLookAtIsValid = false;
			m_bMoveToValid = false;
		}
		
		void Think()
		{
		}

		void ClientSay ( CBaseEntity@ talker, array<string> args )
		{
			// nothing
		}
		
		void setMoveSpeed ( float speed )
		{
			m_fDesiredMoveSpeed = speed;
		}

		void Disconnected ()
		{
			// free stuff
			m_pProfile.m_bUsed = false;
			// Solokiller -- clear the handles out to avoid problems.
			@m_pPlayer = null;
		}
		/** update millisec between each runplayer move */
		private void UpdateMSec() final
		{
			m_iMSecInterval = int( ( g_Engine.time - m_flLastRunMove ) * 1000 );
			
			if( m_iMSecInterval > 255 )
				m_iMSecInterval = 0;
		}
		
		/*
		void RunPlayerMove(edict_t@ pEdict, const Vector& in vecViewAngles,
		 float flFowardMove, float flSideMove, float flUpMove,
		  uint16 iButtons, uint8 iImpulse, uint8 iMsec)
		*/

		void RunPlayerMove() final
		{
		 	float yaw = 0;

			 //m_pPlayer.pev.flags |= FL_GODMODE;

			if ( m_vLookAtIsValid )
			{
				Vector v_Player = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs;
				Vector v_Aim = m_vLookAt - v_Player;

				Vector vAngles = Math.VecToAngles(v_Aim);

				vAngles.x = UTIL_FixFloatAngle(vAngles.x);
				vAngles.y = UTIL_FixFloatAngle(vAngles.y);
				vAngles.z = 0;				

				m_pPlayer.pev.idealpitch = -vAngles.x;
				m_pPlayer.pev.ideal_yaw = vAngles.y;

				m_pPlayer.pev.v_angle.y = m_pPlayer.pev.ideal_yaw;
				m_pPlayer.pev.v_angle.x = m_pPlayer.pev.idealpitch;
				
				m_pPlayer.pev.angles.x = -m_pPlayer.pev.v_angle.x/3;
				m_pPlayer.pev.angles.y = m_pPlayer.pev.v_angle.y;//*/


			}

			m_fUpMove = 0;

			if ( m_bMoveToValid )
			{				
				Vector vMoveTo = m_vMoveTo;

				if ( m_bIsAvoiding )
				{
					Vector vComp = vMoveTo - m_pPlayer.pev.origin;
					Vector vAvoidComp = m_vAvoidVector - m_pPlayer.pev.origin;
					Vector vCross;

					vComp = vComp / vComp.Length();
					
					vCross = UTIL_CrossProduct(vComp,Vector(0,0,1));

					vComp = vComp * vAvoidComp.Length();

					vMoveTo = m_pPlayer.pev.origin + vComp + (vCross*32);				
				}

				yaw = UTIL_yawAngleFromEdict(vMoveTo,m_pPlayer.pev.v_angle,m_pPlayer.pev.origin);

				float z_dist = (m_vMoveTo.z - m_pPlayer.pev.origin.z );
				
				if ( m_pPlayer.pev.waterlevel > 1 )
				{
				if ( z_dist > 0 )
					m_fUpMove = m_fDesiredMoveSpeed;
				else 
					m_fUpMove = -m_fDesiredMoveSpeed;
				}

			
				//BotMessage("Yaw = " + yaw + "\n");
			}
			else
				m_fDesiredMoveSpeed = 0.0f;
				
			UpdateMSec();
			
			m_flLastRunMove = g_Engine.time;

			m_fForwardMove = cos(yaw*0.01745329252) * m_fDesiredMoveSpeed;
			m_fSideMove = sin(yaw*0.01745329252) * m_fDesiredMoveSpeed;		

			//BotMessage("m_fForwardMove = " + m_fForwardMove + "\n");	
			//BotMessage("m_fSideMove = " + m_fSideMove + "\n");	
			//m_fUpMove = cos(v_angles.z*0.01745329252) * m_fDesiredSpeed;

			
			
			
			g_EngineFuncs.RunPlayerMove( m_pPlayer.edict(), m_pPlayer.pev.angles, 
				m_fForwardMove, m_fSideMove, m_fUpMove, 
				m_pPlayer.pev.button, m_pPlayer.pev.impulse, uint8( m_iMSecInterval ) );
		}
	}

	funcdef BaseBot@ CreateBotFn( CBasePlayer@ pPlayer );


	/*
	*	Bot manager class.
	*/
	final class BotManager
	{
		private array<BaseBot@> m_Bots;
		
		private CScheduledFunction@ m_pScheduledFunction;
		private CScheduledFunction@ m_pWaypointDisplay;

		private CreateBotFn@ m_pCreateBotFn;
		
		private bool m_bInitialized = false;

		uint m_iBotQuota = 0;
		float m_fAddBotTime = 0;
		
		BotManager( CreateBotFn@ pCreateBotFn )
		{
			@m_pCreateBotFn = pCreateBotFn !is null ? pCreateBotFn : @CreateDefaultBot;
		}
		
		~BotManager()
		{
			if( m_bInitialized )
			{
				g_Hooks.RemoveHook( Hooks::Game::MapChange, MapChangeHook( this.MapChange ) );
				g_Hooks.RemoveHook( Hooks::Player::ClientDisconnect, ClientDisconnectHook( this.ClientDisconnect ) );
				g_Hooks.RemoveHook( Hooks::Player::ClientSay, ClientSayHook( this.ClientSay ) );
				g_Hooks.RemoveHook( Hooks::Player::PlayerTakeDamage, PlayerTakeDamageHook( this.PlayerTakeDamage) );
			}
		}
		
		private BaseBot@ CreateBot( CBasePlayer@ pPlayer ) const
		{
			return m_pCreateBotFn( pPlayer );
		}

		float getBotFitness ( RCBot@ bot )
		{

				float fBotFitness = 1;		

				if ( bot.m_pPlayer.pev.deadflag < DEAD_RESPAWNABLE )
				{
					fBotFitness += bot.m_pPlayer.pev.frags;

					if ( bot.hasEnemy() )
					{
						fBotFitness *= 2;					
					}
				}

				return fBotFitness;
		}

		RCBot@ getBestBot ()
		{
			BaseBot@ ret = null;
			float fTotalFitness = 0.0f;

			for ( uint i = 0; i < m_Bots.length(); i ++ )
			{
				BaseBot@ bot = m_Bots[i];
				RCBot@ rcbot = cast<RCBot@>(bot);

				fTotalFitness += getBotFitness(rcbot);
			}

			float fRand = Math.RandomFloat(0,fTotalFitness);

			fTotalFitness = 0.0f;

			for ( uint i = 0; i < m_Bots.length(); i ++ )
			{
				BaseBot@ bot = m_Bots[i];
				RCBot@ rcbot = cast<RCBot@>(bot);

				fTotalFitness += getBotFitness(rcbot);

				if ( fRand <= fTotalFitness )
					return rcbot;				
			}			

			return null;		
		}		

		HookReturnCode PlayerTakeDamage ( DamageInfo@ damageInfo )
		{
			BaseBot@ pBot = FindBot(damageInfo.pVictim);

			if ( pBot !is null )
			{
				pBot.hurt(damageInfo);
			}

			return HOOK_CONTINUE;
		}		

		HookReturnCode ClientSay ( SayParameters@ param )
		{
			CBasePlayer@ talker = param.GetPlayer();
			
			array<string> args = param.GetCommand().Split( " " );

			//SayMessage(ListenPlayer(),"YOU TYPED " + args[0] + " | " + args[1]);

			CBasePlayer@ talking_to = UTIL_FindPlayer(args[0],talker,true);

			if ( talker is null )
				return HOOK_CONTINUE;

			if ( talking_to !is null )
			{
				BaseBot@ bot = FindBot(talking_to);

				if ( bot !is null )
				{
					bot.ClientSay(talker,args);
				}
			}


			return HOOK_CONTINUE;
		}

		void ReadConfig ()
		{
			File@ config = g_FileSystem.OpenFile( "scripts/plugins/BotManager/config/config.ini", OpenFile::READ);

			if ( config is null )
				return;

				while ( !config.EOFReached() )
				{
					string fileLine; 
					
					config.ReadLine( fileLine );

					if ( fileLine[0] == "#" )
						continue;

					array<string> args = fileLine.Split( "=" );
					if ( args.length() < 2 )
						continue;

					args[0].Trim(); 
					args[1].Trim();

					if ( args[0] == "quota" )
					{
						int val = atoi(args[1]);

						if ( val <= g_Engine.maxClients )
						{
							m_iBotQuota = uint(val);
						}
					}
					else if ( args[0] == "script_entity_offset" )
					{
						int val = atoi(args[1]);

						g_ScriptEntityOffset = val;					
					}
				}

				config.Close();
		}


		void PluginInit()
		{
			if( m_bInitialized )
				return;
			
			m_bInitialized = true;
			g_MapInit = false;
			
			g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, PlayerTakeDamageHook( this.PlayerTakeDamage) );
			g_Hooks.RegisterHook( Hooks::Player::ClientSay, ClientSayHook( this.ClientSay) );
			g_Hooks.RegisterHook( Hooks::Game::MapChange, MapChangeHook( this.MapChange ) );
			g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, ClientDisconnectHook( this.ClientDisconnect ) );
			//g_Hooks.RegisterHook( Hooks::CEntityFuncs, DispatchKeyValueHook(this.DispatchKeyValue) );
			@m_pScheduledFunction = g_Scheduler.SetInterval( @this, "Think", 0.1 );
			@m_pWaypointDisplay = g_Scheduler.SetInterval(@this, "WaypointDisplay", 1);

			ReadConfig();

			m_fAddBotTime = g_Engine.time + 10.0f;

			//If the plugin was reloaded, find all bots and add them again.
			for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
			{
				CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
				
				if( pPlayer is null )
					continue;
					
				if( ( pPlayer.pev.flags & FL_FAKECLIENT ) == 0 )
					continue;
					
				g_Game.AlertMessage( at_console, "BotManager: Found bot %1\n", pPlayer.pev.netname );
					
				m_Bots.insertLast( @CreateBot( @pPlayer ) );
			}

			g_WaypointsLoaded = false;

		}
		
		HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer )
		{
			//Note: this will be called when a bot gets created. The Bot instance for it is created afterwards, so Spawn gets called in CreateBot instead.
			BaseBot@ pBot = FindBot( pPlayer );
			
			if( pBot !is null )
				pBot.Spawn();
			
			return HOOK_CONTINUE;
		}
		
		HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
		{
			if( ( pPlayer.pev.flags & FL_FAKECLIENT ) != 0 )
				RemoveBot( pPlayer, false );
			
			return HOOK_CONTINUE;
		}
		
		HookReturnCode MapChange()
		{
		    m_fAddBotTime = g_Engine.time + 5.0f;

			m_Bots.resize( 0 );
			
			g_Profiles.resetProfiles();
			//g_Game.PrecacheModel("models/mechgibs.mdl");

			//g_MasterEntities = CMasterEntities();
			g_bTeleportSet = false;

			g_WaypointsLoaded = false;

			return HOOK_CONTINUE;
		}
		
		uint GetBotCount() const
		{
			return m_Bots.length();
		}
		
		BaseBot@ GetBot( const uint uiIndex ) const
		{
			if( uiIndex >= m_Bots.length() )
				return null;
				
			return m_Bots[ uiIndex ];
		}
		
		BaseBot@ FindBot( const CBaseEntity@ pPlayer ) const
		{
			if( pPlayer is null )
				return null;
				
			for( uint uiIndex = 0; uiIndex < m_Bots.length(); ++uiIndex )
			{
				BaseBot@ pBot = m_Bots[ uiIndex ];
				
				if( pBot !is null && pPlayer is pBot.Player )
				{
					return pBot;
				}
			}
			
			return null;
		}
		
		BaseBot@ CreateBot( )
		{	
			BotProfile@ profile = g_Profiles.getRandomProfile();

			if ( profile is null )
			{
				g_Game.AlertMessage( at_console, "No bot profiles are free!" );
				return null;
			}		

			CBasePlayer@ pPlayer = g_PlayerFuncs.CreateBot( profile.m_Name );
			
			if( pPlayer is null )
			{
				g_Game.AlertMessage( at_console, "Could not create bot\n" );
				return null;
			}

			profile.m_bUsed = true;

			BaseBot@ pBot = CreateBot( pPlayer );

			if ( pBot !is null )
			{
				@pBot.m_pProfile = profile;

				KeyValueBuffer@ pInfoBuffer = g_EngineFuncs.GetInfoKeyBuffer(pPlayer.edict());

				// choose model and skin colour

				pInfoBuffer.SetValue("model",profile.skin);				
				pInfoBuffer.SetValue( "topcolor", Math.RandomLong( 0, 255 ) );
				pInfoBuffer.SetValue( "bottomcolor", Math.RandomLong( 0, 255 ) );

				// Stuff from Rcbot1 / Hpb_bot 1

				pInfoBuffer.SetValue( "rate", 3500 );
				pInfoBuffer.SetValue( "cl_updaterate", 20 );
				pInfoBuffer.SetValue( "cl_lw", 1 );
				pInfoBuffer.SetValue( "cl_lc", 1 );
				pInfoBuffer.SetValue( "cl_dlmax", 128 );
				pInfoBuffer.SetValue( "_vgui_menus", 0 );
				pInfoBuffer.SetValue( "_ah", 0 );
				pInfoBuffer.SetValue( "dm", 0 );
				pInfoBuffer.SetValue( "tracker", 0 );				

				m_Bots.insertLast( pBot );
				
				pBot.Spawn();

				g_Game.AlertMessage( at_console, "Created bot " + profile.m_Name + "\n" );
				
				return pBot;
			}
			else
				g_Game.AlertMessage( at_console, "Could not create bot\n" );

			return null;
		}

		BaseBot@ RandomBot ( )
		{
			BaseBot@ ret = null;

			if ( m_Bots.length () > 0 ) 
			{
				@ret = m_Bots[Math.RandomLong(0,m_Bots.length()-1)];
			}

			return ret;
		}		
		
		void RemoveBot( BaseBot@ pBot, const bool bDisconnect )
		{
			if( pBot is null )
				return;
				
			int iIndex = m_Bots.findByRef( @pBot );
			
			if( iIndex != -1 )
			{
				m_Bots.removeAt( uint( iIndex ) );

				pBot.Disconnected();
				
				if( bDisconnect )
					g_PlayerFuncs.BotDisconnect( pBot.Player );
			}
		}
		
		void RemoveBot( CBasePlayer@ pPlayer, const bool bDisconnect )
		{
			if( pPlayer is null )
				return;

			BaseBot@ pBot = FindBot( pPlayer );
			
			if( pBot !is null && pPlayer is pBot.Player )
			{
				RemoveBot( pBot, bDisconnect );
			}
		}
		
		void Think()
		{
			for( uint uiIndex = 0; uiIndex < m_Bots.length(); ++uiIndex )
			{
				BaseBot@ pBot = m_Bots[ uiIndex ];
				
				pBot.Think();
				pBot.RunPlayerMove();
			}

			if ( m_Bots.length() < m_iBotQuota )
			{
				if ( m_fAddBotTime < g_Engine.time )
				{
					BotManager::BaseBot@ pBot = g_BotManager.CreateBot( );

					m_fAddBotTime = g_Engine.time + 5.0f;
				}
			}
			
			g_Waypoints.runVisibility();

			g_BotCam.Think();

			if ( g_WaypointsLoaded == false && g_MapInit == true )
			{
				if ( g_Waypoints.Load() )
					BotMessage("Waypoints Loaded!");
				else
					BotMessage("No waypoints!");

				g_WaypointsLoaded = true;
				g_MapInit = false;
			}
			
		}

		void WaypointDisplay ()
		{

			//If the plugin was reloaded, find all bots and add them again.
			for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
			{
				CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
				
				if( pPlayer is null )
					continue;				
					
				// not a bot
				if( ( pPlayer.pev.flags & FL_FAKECLIENT ) == 0 )
				{				
					g_Waypoints.DrawWaypoints(pPlayer);
				}
			}
		}
	}

	/*
	*	Default bot. Will stand in place and do nothing.
	*/
	final class DefaultBot : BaseBot
	{
		DefaultBot( CBasePlayer@ pPlayer )
		{
			super( pPlayer );
		}
	}

	BaseBot@ CreateDefaultBot( CBasePlayer@ pPlayer )
	{
		return @DefaultBot( pPlayer );
	}
}