#pragma semicolon 1
#include <sdktools>

new bool:SpawnKiller = false;
#define PLUGIN_URL "https://github.com/Heyter/-CS-GO-Hunger-Games"

public Plugin:myinfo =
{
    name = "Kill Late Players",
    author = "Johnny",
    description = "Kills players who join late",
    version = "1.0",
    url = PLUGIN_URL,
}

public OnPluginStart()
{
	HookEvent("round_start", EventRoundStart);
	HookEvent("round_end", EventRoundEnd);
	HookEvent("player_spawn", EventPlayerSpawn);
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	CreateTimer(20.0, ActivateSpawnKill, INVALID_HANDLE); //Amount of seconds after round starts to kill people
}

public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	SpawnKiller = false;
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (SpawnKiller)
	{
		ForcePlayerSuicide(client);
	}
}

public Action:ActivateSpawnKill(Handle:timer)
{
	SpawnKiller = true;
}
