
final class CWeapon 
{
    string m_szName;
    bool m_bCanUseUnderWater;
    float m_fMinDistance;
    float m_fMaxDistance;
}

final class CBotWeapon
{
    CWeapon@ m_pWeaponInfo;
    bool m_bHasWeapon;
    int m_iAmmo; // etc    

}

final class CBotWeapons
{
    array<CBotWeapon@> m_pWeapons;

    CBotWeapon@ findBestWeapon ( CBasePlayer@ pBot, CBaseEntity@ target )
    {
        // check if underwater
        // check distance from target
        //target.pev.origin - 
        // check ammo
        // check requirement such as explosive etc
    }

//    void addWeapon ( CWeapon pWeapon )
}
