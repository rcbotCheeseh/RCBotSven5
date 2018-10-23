#include "UtilFuncs"
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
			m_vMoveTo = origin;
			m_bMoveToValid = true;
			BotMessage("setMove!");
		}

		void setLookAt ( Vector origin )
		{
			m_vLookAtIsValid = true;
			m_vLookAt = origin;
		}
				
		float m_fUpMove;
		float m_fSideMove;
		float m_fForwardMove;		

		float m_fDesiredSpeed = 320;	

		Vector m_vLookAngles = Vector(0,0,0);
		
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

			if ( m_vLookAtIsValid )
			{
				m_vLookAngles = Math.VecToAngles(m_vLookAt - m_pPlayer.pev.origin);

				m_vLookAngles.x = UTIL_FixFloatAngle(m_vLookAngles.x);
				m_vLookAngles.y = UTIL_FixFloatAngle(m_vLookAngles.y);
				m_vLookAngles.z = UTIL_FixFloatAngle(m_vLookAngles.z);

				m_pPlayer.pev.v_angle = m_vLookAngles;
				
				m_pPlayer.pev.idealpitch = -m_vLookAngles.x;
				m_pPlayer.pev.ideal_yaw = m_vLookAngles.y;

				m_pPlayer.pev.angles.x = m_pPlayer.pev.v_angle.x/3;
				m_pPlayer.pev.angles.y = m_pPlayer.pev.v_angle.y;
				m_pPlayer.pev.angles.z = 0;
			}

			if ( m_bMoveToValid )
			{				
				yaw = UTIL_yawAngleFromEdict(m_vMoveTo,m_pPlayer.pev.v_angle,m_pPlayer.pev.origin);

				BotMessage("Yaw = " + yaw + "\n");

				m_fDesiredSpeed = 320.0f;
			}
			else
				m_fDesiredSpeed = 0.0f;
				
			UpdateMSec();
			
			m_flLastRunMove = g_Engine.time;

			m_fForwardMove = cos(yaw*0.01745329252) * m_fDesiredSpeed;
			m_fSideMove = sin(yaw*0.01745329252) * m_fDesiredSpeed;		

			//BotMessage("m_fForwardMove = " + m_fForwardMove + "\n");	
			//BotMessage("m_fSideMove = " + m_fSideMove + "\n");	
			//m_fUpMove = cos(v_angles.z*0.01745329252) * m_fDesiredSpeed;
			m_fUpMove = 0;			
			
			g_EngineFuncs.RunPlayerMove( m_pPlayer.edict(), m_pPlayer.pev.angles, 
				m_fForwardMove, m_fSideMove, m_fUpMove, 
				m_pPlayer.pev.button, m_pPlayer.pev.impulse, uint8( m_iMSecInterval ) );
		}
	}

	funcdef BaseBot@ CreateBotFn( CBasePlayer@ pPlayer );

	BotProfiles g_Profiles;

	final class BotProfile
	{
		string m_Name;
		int m_Skill;
		bool m_bUsed;

		BotProfile ( string name, int skill )
		{
			m_Name = name;
			m_Skill = skill;
			m_bUsed = false;
		}	
	}

	final class BotProfiles
	{
		array<BotProfile@> m_Profiles;
		
		BotProfiles()
		{
			m_Profiles.insertLast(BotProfile("[m00]m1lk",1));
			m_Profiles.insertLast(BotProfile("[m00]wh3y",2));
			m_Profiles.insertLast(BotProfile("[m00]y0ghur7",3));
			m_Profiles.insertLast(BotProfile("[m00]ch33s3",4));
		}

		BotProfile@ getRandomProfile ()
		{
			array<BotProfile@> UnusedProfiles;

			for ( uint i = 0; i < m_Profiles.length(); i ++ )
			{
				if ( !m_Profiles[i].m_bUsed )
				{
					UnusedProfiles.insertLast(m_Profiles[i]);
				}
			}

			if ( UnusedProfiles.length() > 0 )
			{
				return UnusedProfiles[Math.RandomLong(0, UnusedProfiles.length()-1)];
			}

			return null;
		}
	}

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