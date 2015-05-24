#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "[HG] Disarm weapons"
#define PLUGIN_AUTHOR "Hejter"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL "https://github.com/Heyter/-CS-GO-Hunger-Games"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL,
};

public OnPluginStart()
{
    HookEvent("player_spawn", OnPlayerSpawn);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
    if (IsPlayerAlive(client))  
    {
        DisarmWeapons(client);
    }
}

public DisarmWeapons(client)
{
	for (new i = 0; i < 5; i++)
	{
	    if (GetPlayerWeaponSlot(client, i) > -1)
	    {
	        RemovePlayerItem(client, GetPlayerWeaponSlot(client, i));
	    }
	}
}
