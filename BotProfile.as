
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
            m_Profiles.insertLast(BotProfile("[m00]3gg",4));
            m_Profiles.insertLast(BotProfile("[m00]h3n",3));
            m_Profiles.insertLast(BotProfile("[m00]c0w",2));
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