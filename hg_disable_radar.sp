#include <sourcemod>

#define HIDE_RADAR_CSGO 1<<12

#define PLUGIN_NAME "[HG] Disable Radar"
#define PLUGIN_AUTHOR "Hejter"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL "hlmod.ru & excw.ru"

new String:strGame[10];

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL,
};

public OnPluginStart() 
{
	HookEvent("player_spawn", Player_Spawn);
	
	GetGameFolderName(strGame, sizeof(strGame));
	
	if(StrContains(strGame, "cstrike") != -1) 
		HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post);
}
public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.0, RemoveRadar, client);
}  

public Action:RemoveRadar(Handle:timer, any:client) 
{    
	if(StrContains(strGame, "csgo") != -1) SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDE_RADAR_CSGO);
	else if(StrContains(strGame, "cstrike") != -1) 
		CSSHideRadar(client);
} 

public Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (client && GetClientTeam(client) > 1)
	{
		new Float:fDuration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
		CreateTimer(fDuration, RemoveRadar, client);
	}
}

CSSHideRadar(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 3600.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
}
