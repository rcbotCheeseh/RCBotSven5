
CBotWeaponsInfo@ g_WeaponInfo = CBotWeaponsInfo();

const int WEAP_FL_NONE = 0;
const int WEAP_FL_MELEE = 1;
const int WEAP_FL_UNDERWATER = 2;
const int WEAP_FL_SECONDARY = 4;
const int WEAP_FL_PRIMARY_EXPLOSIVE = 8;
const int WEAP_FL_SECONDARY_EXPLOSIVE = 16;
const int WEAP_FL_GRENADE = 32;
const int WEAP_FL_SNIPE = 32;

final class CBotWeaponInfo
{
    string m_szName;

    float m_fMinDistance;
    float m_fMaxDistance;

    int m_iPriority;

    int m_iFlags;

    bool hasFlags ( int flags )
    {
        return m_iFlags & flags == flags;
    }

    CBotWeaponInfo ( string name, float min_dist, float max_dist, int flags, int priority )
    {
        m_szName = name;
        m_fMinDistance = min_dist;
        m_fMaxDistance = max_dist;
        m_iPriority = priority;
        m_iFlags = flags;
    }
}

final class CBotWeaponsInfo
{
    array<CBotWeaponInfo@> m_pWeaponInfo;

    CBotWeaponsInfo ()
    {
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_crowbar",0.0,100.0,WEAP_FL_MELEE|WEAP_FL_UNDERWATER,10));        
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_9mmhandgun",0.0,1500.0,WEAP_FL_UNDERWATER,1));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_shotgun",0.0,768.0,WEAP_FL_NONE,8));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_357",0.0,2000.0,WEAP_FL_NONE,7));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_9mmAR",0.0,2000.0,WEAP_FL_NONE|WEAP_FL_SECONDARY|WEAP_FL_SECONDARY_EXPLOSIVE,10));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_crossbow",0.0,4000.0,WEAP_FL_SNIPE|WEAP_FL_UNDERWATER,14));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_egon",100.0,2000.0,WEAP_FL_NONE,12));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_hornetgun",0.0,2000.0,WEAP_FL_UNDERWATER,6));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_m16",0.0,2000.0,WEAP_FL_NONE,13));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_pipewrench",0.0,100.0,WEAP_FL_MELEE|WEAP_FL_UNDERWATER,15));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_rpg",400.0,5000.0,WEAP_FL_PRIMARY_EXPLOSIVE|WEAP_FL_UNDERWATER,16));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_shockrifle",100.0,2000.0,WEAP_FL_NONE,9));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_snark",300.0,2000.0,WEAP_FL_GRENADE,10));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_uzi",100.0,2000.0,WEAP_FL_NONE|WEAP_FL_UNDERWATER,8));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_medkit",0.0,0.0,WEAP_FL_NONE,0)); // will be handled in task code
    }

    int numWeapons ()
    {
        return m_pWeaponInfo.length();        
    }

    CBotWeaponInfo@ getWeapon ( int i )
    {
        return m_pWeaponInfo[i];
    }
}

bool Weapon_hasAmmo ( CBasePlayer@ player, CBasePlayerWeapon@ weapon )
{
    int index = weapon.PrimaryAmmoIndex();

    return (index == -1) || (player.m_rgAmmo(index) > 0);
}

CBasePlayerWeapon@ findBestWeapon ( CBasePlayer@ pBot, Vector targetOrigin, CBaseEntity@ target = null )
{
    CBasePlayerWeapon@ weapon = null;
    int priority = 0;

    for ( int i = 0; i < g_WeaponInfo.numWeapons(); i ++ )
    {
        CBotWeaponInfo@ weaponInfo = g_WeaponInfo.getWeapon(i);
        CBasePlayerItem@ item = pBot.HasNamedPlayerItem(weaponInfo.m_szName);
        CBasePlayerWeapon@ tmpWeapon;

        if ( item is null )
            continue;

        @tmpWeapon = item.GetWeaponPtr();

        if ( tmpWeapon is null )    
            continue;

        // out of ammo
        if ( !Weapon_hasAmmo(pBot,tmpWeapon) )
            continue;

        if ( pBot.pev.waterlevel > 1 && !weaponInfo.hasFlags(WEAP_FL_UNDERWATER) )
            continue;

        float distance = (pBot.pev.origin - targetOrigin).Length();

        if ( distance < weaponInfo.m_fMinDistance )
            continue;

        if ( distance > weaponInfo.m_fMaxDistance )
            continue;

        if ( weaponInfo.m_iPriority <= priority )
            continue;
        
        priority = weaponInfo.m_iPriority;
        @weapon = tmpWeapon;
    }

    return weapon;
}
