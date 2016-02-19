#pragma semicolon 1
#include <sdktools>

// Force 1.7 syntax
#pragma newdecls required

int g_iGrenadeOffsets[] = {15, 17, 16, 14, 18, 17};

public Plugin myinfo =
{
	name = "[HG:CSGO] Disarm Weapons",
	author = "Hejter",
	version = "0.2",
	url = "hlmod.ru & excw.ru",
};

public void OnPluginStart()
{
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
	
    if (client && IsClientInGame(client) && IsPlayerAlive(client)) 
    {
        for (int i = 0; i < 5; ++i)
        {
        	if (i == 3) RemoveNades(client);
        	else RemoveWeaponBySlot(client, i);
        }
    }
    return Plugin_Continue;
}

// Thanks White Wolf (hlmod.ru)
stock void RemoveNades(int client)
{
	while (RemoveWeaponBySlot(client, 3))
	{
		for (int i = 0; i < 6; i++)
			SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, g_iGrenadeOffsets[i]);
	}
}

stock bool RemoveWeaponBySlot(int client, int slot)
{
	int entity = GetPlayerWeaponSlot(client, slot);
	if (IsValidEdict(entity))
	{
		RemovePlayerItem(client, entity);
		AcceptEntityInput(entity, "Kill");
		return true;
	}
	return false;
}