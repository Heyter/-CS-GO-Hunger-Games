#pragma semicolon 1
#include <sdktools>

#define PLUGIN_NAME "[HG] RoundEndAnnounce"
#define PLUGIN_AUTHOR "Hejter & johny01"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL "hlmod.ru & excw.ru"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL,
};

public OnPluginStart()
{
	HookEvent("round_end", EventRoundEnd);
}

public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetPlayerCount() >= 2)
	{
		for (client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
				ForcePlayerSuicide(client);
		}
	}
	else if (GetPlayerCount() == 1)
	{	
		for (client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				new rHealth = GetClientHealth(client);
				new rArmor = GetEntProp(client, Prop_Send, "m_ArmorValue");
				new String:player[32];
				GetClientName(client, player, sizeof(player));
				
				PrintToChatAll(" \x04%s \x05выиграл раунд со [%d Здоровьем || %d Брони]", player, rHealth, rArmor);
			}
		}
	}
}


stock GetPlayerCount()
{
	new players;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) >= 2)
		{
			players++;
		}
	}
	return players;
}
