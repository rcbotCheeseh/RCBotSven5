#include "UtilFuncs"
#include "BotProfile"
/*
*	This file defines the interface to the bot manager
*	This is a sample script.
*/

namespace BotManager
{

	/*
	*	Base class for bots.
	*/
	abstract class BaseBot
	{
		CBasePlayer@ m_pPlayer;
		
		private int m_iMSecInterval = 0;
		private float m_flLastRunMove = 0;

		BotProfile@ m_pProfile;

		int m_iMovePriority = 0;
		int m_iLookPriority = 0;
		int m_iCurrentPriority = 0;

		Vector m_vMoveTo;
		bool m_bMoveToValid;

		Vector m_vLookAt;
		bool m_vLookAtIsValid;

		void ReleaseButtons ( )
		{
			m_pPlayer.pev.button = 0;
		}

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

		void setLookAt ( Vector origin )
		{
			if ( m_iCurrentPriority >= m_iLookPriority )
			{
				m_vLookAtIsValid = true;
				m_vLookAt = origin;
			}
		}
				
		float m_fUpMove;
		float m_fSideMove;
		float m_fForwardMove;		
		float m_fDesiredMoveSpeed = 0;

		bool m_bIsAvoiding = false;
		Vector m_vAvoidVector;

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


		
		void setMoveSpeed ( float speed )
		{
			m_fDesiredMoveSpeed = speed;
		}



		void Disconnected ()
		{
			// free stuff
			m_pProfile.m_bUsed = false;
		}
		
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

					vComp = vComp * (vAvoidComp.Length()+32);

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
				
			}
		}
		
		private BaseBot@ CreateBot( CBasePlayer@ pPlayer ) const
		{
			return m_pCreateBotFn( pPlayer );
		}
		
		void PluginInit()
		{
			if( m_bInitialized )
				return;
			
			m_bInitialized = true;
				
			g_Hooks.RegisterHook( Hooks::Game::MapChange, MapChangeHook( this.MapChange ) );
			g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, ClientDisconnectHook( this.ClientDisconnect ) );
			//g_Hooks.RegisterHook( Hooks::CEntityFuncs, DispatchKeyValueHook(this.DispatchKeyValue) );
			@m_pScheduledFunction = g_Scheduler.SetInterval( @this, "Think", 0.1 );
			@m_pWaypointDisplay = g_Scheduler.SetInterval(@this, "WaypointDisplay", 1);

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

			g_Waypoints.Load();
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
			m_Bots.resize( 0 );

			//g_MasterEntities = CMasterEntities();

			if ( g_Waypoints.Load() )
				BotMessage("Waypoints Loaded!");
			else
				BotMessage("No waypoints!");
			
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
		
		BaseBot@ FindBot( CBasePlayer@ pPlayer ) const
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

				KeyValueBuffer@ infoBuffer = g_EngineFuncs.GetInfoKeyBuffer(pPlayer.edict());

				infoBuffer.SetValue("model",profile.skin);				

				m_Bots.insertLast( pBot );
				
				pBot.Spawn();

				g_Game.AlertMessage( at_console, "Created bot " + profile.m_Name + "\n" );
				
				return pBot;
			}
			else
				g_Game.AlertMessage( at_console, "Could not create bot\n" );

			return null;
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

			g_Waypoints.runVisibility();
		
			/*CBasePlayer@ player = g_PlayerFuncs.FindPlayerByIndex( 1 );

			if ( player !is null )
			{
				Observer@ o = player.GetObserver();	

				if ( o !is null )
				{
					if ( g_NoTouchChange )
					{
						g_NoTouchChange = false;	

						if ( g_NoTouch == false )
						{
							o.StopObserver(true);
						}
						else
						{
							o.StartObserver(player.pev.origin, player.pev.angles, false);
						}
					}
					else if ( g_NoTouch )
					{
						
						o.SetMode(OBS_ENTERING);
						o.SetObserverModeControlEnabled(true);	
					}
				}
			}*/
				
			
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