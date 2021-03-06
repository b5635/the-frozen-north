#include "inc_persist"
#include "inc_debug"
#include "inc_henchman"
#include "inc_quest"
#include "nwnx_util"
#include "inc_sql"
#include "inc_general"
#include "nwnx_time"
#include "nwnx_player"

void DoRevive(object oDead)
{
        if (GetIsInCombat(oDead)) return;
        if (GetIsDead(oDead))
        {
            SendDebugMessage(GetName(oDead)+" is dead, start revive loop");
            int bEnemy = FALSE;
            int bFriend = FALSE;
            int bMasterFound = FALSE;
            int nFaction, nRace;

            string sReviveMessage = "";

            int nTimesRevived = GetTimesRevived(oDead);

            if (nTimesRevived >= 3)
            {
                sReviveMessage = " can no longer be revived without raise dead*";
            }
            else if (nTimesRevived == 2)
            {
                sReviveMessage = " can be revived one more time*";
            }
            else if (nTimesRevived == 1)
            {
                sReviveMessage = " can be revived two more times*";
            }

            object oMaster = GetMasterByUUID(oDead);
            int bMasterDead = GetIsDead(oMaster);

            object oLastFriend;

            location lLocation = GetLocation(oDead);

            float fSize = 30.0;

            float fMasterDistance = GetDistanceBetween(oDead, oMaster);
            if (fMasterDistance <= 90.0) bMasterFound = TRUE;

            if (GetArea(oMaster) != GetArea(oDead)) bMasterFound = FALSE;

            object oCreature = GetFirstObjectInShape(SHAPE_SPHERE, fSize, lLocation, TRUE, OBJECT_TYPE_CREATURE);

            while (GetIsObjectValid(oCreature))
            {
// do not count self and count only if alive
                if (!GetIsDead(oCreature) && (oCreature != oDead))
                {
                    nRace = GetRacialType(oCreature);
                    // added check to see if they have a master, if so check if it is an enemy to their master as well
                    if (GetIsEnemy(oCreature, oDead) || (GetIsObjectValid(oMaster) && GetIsEnemy(oCreature, oMaster)))
                    {
                        bEnemy = TRUE;
                        SendDebugMessage("Enemy detected, breaking from revive loop: "+GetName(oCreature));
                        break;
                    }
                    else if (!bFriend && GetIsFriend(oCreature, oDead) && nRace != RACIAL_TYPE_ANIMAL && nRace != RACIAL_TYPE_VERMIN && !GetIsInCombat(oCreature))
                    {
                        bFriend = TRUE;
                        oLastFriend = oCreature;
                        SendDebugMessage("Friend detected: "+GetName(oCreature));
                    }
                    else if (nRace != RACIAL_TYPE_ANIMAL && nRace != RACIAL_TYPE_VERMIN && !bFriend && !GetIsInCombat(oCreature) && (GetIsFriend(oCreature, oDead) || GetIsNeutral(oCreature, oDead)))
                    {
                        nFaction = NWNX_Creature_GetFaction(oCreature);

                        if (nFaction == STANDARD_FACTION_COMMONER || nFaction == STANDARD_FACTION_DEFENDER || nFaction == STANDARD_FACTION_MERCHANT)
                        {
                            bFriend = TRUE;
                            oLastFriend = oCreature;
                            SendDebugMessage("Commoner/Defender/Merchant detected: "+GetName(oCreature));
                        }
                    }

                }

                oCreature = GetNextObjectInShape(SHAPE_SPHERE, fSize, lLocation, TRUE, OBJECT_TYPE_CREATURE);
            }

            if (GetStringLeft(GetResRef(oDead), 3) == "hen" && bMasterFound && !bMasterDead)
            {
                oLastFriend = oMaster;
                bFriend = TRUE;
            }

            if (!bEnemy && bFriend && IsCreatureRevivable(oDead))
            {
                SQLocalsPlayer_DeleteInt(oDead, "DEAD");
                ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectResurrection(), oDead);

                DetermineDeathEffectPenalty(oDead, 1);

                if (GetStringLeft(GetResRef(oDead), 3) == "hen" && bMasterFound) SetMaster(oDead, oMaster);

                object oFactionPC = GetFirstFactionMember(oDead);
                while (GetIsObjectValid(oFactionPC))
                {
                    if (GetIsObjectValid(oLastFriend))
                        NWNX_Player_FloatingTextStringOnCreature(oFactionPC, oDead, "*"+GetName(oDead)+" was revived by "+GetName(oLastFriend)+".");

                    if (sReviveMessage != "")
                        DelayCommand(3.0, NWNX_Player_FloatingTextStringOnCreature(oFactionPC, oDead, "*"+GetName(oDead)+sReviveMessage));

                    oFactionPC = GetNextFactionMember(oDead);
                }
                WriteTimestampedLogEntry(GetName(oDead)+" was revived by friendly "+GetName(oLastFriend)+".");
            }

// destroy henchman if still not alive and master isn't found
            if (!GetIsPC(oDead) && GetIsDead(oDead) && GetStringLeft(GetResRef(oDead), 3) == "hen" && !bMasterFound)
            {
                 ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_RESTORATION), lLocation);
                 ClearMaster(oDead);
                 DestroyObject(oDead);
            }
        }
}


void main()
{
    object oPC = GetFirstPC();

    ExportAllCharacters();

    string sBounties = GetLocalString(GetModule(), "bounties");

    if (GetIsObjectValid(oPC))
    {
        int nTickCount = NWNX_Util_GetServerTicksPerSecond();
        if (nTickCount <= 50) SendDebugMessage("Low tick count detected: "+IntToString(nTickCount), TRUE);
    }

    int nTime = NWNX_Time_GetTimeStamp();

    while(GetIsObjectValid(oPC))
    {
        DoRevive(oPC);

        RefreshCompletedBounties(oPC, nTime, sBounties);

        if (!GetIsDead(oPC))
            SQLocalsPlayer_DeleteInt(oPC, "DEAD");

        SavePCInfo(oPC);

        oPC = GetNextPC();
    }

    DoRevive(GetObjectByTag("hen_tomi"));
    DoRevive(GetObjectByTag("hen_daelan"));
    DoRevive(GetObjectByTag("hen_sharwyn"));
    DoRevive(GetObjectByTag("hen_linu"));
    DoRevive(GetObjectByTag("hen_boddyknock"));
    DoRevive(GetObjectByTag("hen_grimgnaw"));
}
