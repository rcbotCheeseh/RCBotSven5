
CBotWeaponsInfo@ g_WeaponInfo = CBotWeaponsInfo();

final class CBotWeaponInfo
{
    string m_szName;
    bool m_bCanUseUnderWater;
    float m_fMinDistance;
    float m_fMaxDistance;
    bool m_bCanUseSecondary;
    int m_iPriority;

    CBotWeaponInfo ( string name, float min_dist, float max_dist, bool secondary,  bool underwater,  int priority )
    {
        m_szName = name;
        m_bCanUseSecondary = secondary;
        m_bCanUseUnderWater = underwater;
        m_fMinDistance = min_dist;
        m_fMaxDistance = max_dist;
        m_iPriority = priority;
    }
}

final class CBotWeaponsInfo
{
    array<CBotWeaponInfo@> m_pWeaponInfo;

    CBotWeaponsInfo ()
    {
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_crowbar",0.0,100.0,false,true,10));        
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_9mmhandgun",0.0,1500.0,false,true,1));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_shotgun",0.0,768.0,false,true,8));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_357",0.0,2000.0,false,false,7));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_9mmAR",0.0,2000.0,true,false,10));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_crossbow",0.0,4000.0,false,true,14));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_egon",100.0,2000.0,false,false,12));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_hornetgun",0.0,2000.0,false,false,6));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_m16",0.0,2000.0,false,false,13));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_pipewrench",0.0,100.0,false,true,15));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_rpg",400.0,5000.0,false,true,16));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_shockrifle",100.0,2000.0,false,false,9));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_snark",300.0,2000.0,false,false,10));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_uzi",100.0,2000.0,false,false,8));
        m_pWeaponInfo.insertLast(CBotWeaponInfo("weapon_medkit",0.0,0.0,false,false,0)); // will be handled in task code
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

        if ( pBot.pev.waterlevel > 0 && weaponInfo.m_bCanUseUnderWater == false )
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
