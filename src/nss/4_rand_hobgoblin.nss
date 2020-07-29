#include "nwnx_creature"
#include "x0_i0_anims"

void main()
{
    object oWeapon, oAmmo, oBackup;
    switch (d3())
    {
        case 1:
        case 2:
            oWeapon = CreateItemOnObject("nw_wswbs001", OBJECT_SELF);
        break;
        case 3:
            oWeapon = CreateItemOnObject("nw_wbwxh001", OBJECT_SELF);
            oAmmo = CreateItemOnObject("nw_wambo001", OBJECT_SELF, 99);
            oBackup = CreateItemOnObject("nw_wswss001");

            SetDroppableFlag(oBackup, FALSE);
            SetPickpocketableFlag(oBackup, FALSE);
            SetDroppableFlag(oAmmo, FALSE);
            SetPickpocketableFlag(oAmmo, FALSE);

            AssignCommand(OBJECT_SELF, ActionEquipItem(oAmmo, INVENTORY_SLOT_BOLTS));
            SetCombatCondition(X0_COMBAT_FLAG_RANGED);
        break;
    }

    AssignCommand(OBJECT_SELF, ActionEquipItem(oWeapon, INVENTORY_SLOT_RIGHTHAND));

    SetDroppableFlag(oWeapon, FALSE);
    SetPickpocketableFlag(oWeapon, FALSE);
}