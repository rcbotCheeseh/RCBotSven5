	const uint MAX_PROFILES = 64;

	BotProfiles g_Profiles;

	final class BotProfile
	{
		string m_Name;
		int m_Skill;
		bool m_bUsed;
		string skin;

		BotProfile ( string name, int skill, string model = "gordon" )
		{
			m_Name = name;
			m_Skill = skill;
			m_bUsed = false;
			skin = model;
		}	
	}

	final class BotProfiles
	{
		array<BotProfile@> m_Profiles;
		
		BotProfiles()
		{
			/*m_Profiles.insertLast(BotProfile("[m00]m1lk",1,"freeman"));
			m_Profiles.insertLast(BotProfile("[m00]wh3y",2,"scientist6"));
			m_Profiles.insertLast(BotProfile("[m00]y0ghur7",3,"OP4_Lance"));
			m_Profiles.insertLast(BotProfile("[m00]ch33s3",4,"betagordon"));
            m_Profiles.insertLast(BotProfile("[m00]3gg",4,"aswat"));
            m_Profiles.insertLast(BotProfile("[m00]h3n",3,"OP4_Sniper"));
            m_Profiles.insertLast(BotProfile("[m00]c0w",2,"th_jack"));*/
			readProfiles();
		}

		void readProfiles()
		{
			string botName;
			int botSensitivity;
			string botModel;

			for ( uint i = 1; i < MAX_PROFILES; i ++ )
			{
				File@ profileFile = g_FileSystem.OpenFile( "scripts/plugins/BotManager/profiles/" + i + ".ini", OpenFile::READ);
				if ( profileFile is null )
					continue;

				botName = "Unnamed";
				botSensitivity = Math.RandomLong( 1, 4 );
				botModel = "freeman";

				while ( !profileFile.EOFReached() )
				{
					string fileLine; profileFile.ReadLine( fileLine );
					if ( fileLine[0] == "#" )
						continue;

					array<string> args = fileLine.Split( "=" );
					if ( args.length() < 2 )
						continue;
					args[0].Trim(); args[1].Trim();

					if ( args[0] == "name" )
						botName = args[1];
					
					if ( args[0] == "sensitivity" )
					{
						int sensitivity = atoi(args[1]);
						if ( sensitivity != 0 )
							botSensitivity = sensitivity;
					}

					if ( args[0] == "model" )
						botModel = args[1];
				}

				m_Profiles.insertLast(BotProfile(botName, botSensitivity, botModel));
			}
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