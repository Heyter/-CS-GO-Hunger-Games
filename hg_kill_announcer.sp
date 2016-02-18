#pragma semicolon 1
#include <csgo_colors>
 
public OnPluginStart()
{
    HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
    HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Pre);
    HookUserMessage(GetUserMessageId("TextMsg"), Hook_TextMsg, true); 
}
 
public Action:Hook_TextMsg(UserMsg:msg_id, Handle:msg, const players[], playersNum, bool:reliable, bool:init)
{
    new String:m_szMessage[256];
    PbReadString(msg, "params", m_szMessage, sizeof(m_szMessage), 0);
    if(strcmp(m_szMessage, "#Player_Cash_Award_Killed_Enemy")==0)
        return Plugin_Stop;
    return Plugin_Continue;
}
 
public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(client)
        SetEntProp(client, Prop_Send, "m_iAccount", 0);
    return Plugin_Continue;
}
 
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
 
	if(attacker)
		SetEntProp(attacker, Prop_Send, "m_iAccount", 0);
 
	new alive = 0;
	for(new i=1;i<=MaxClients;++i)
	{
		if(!IsClientInGame(i))
			continue;
		
		if(IsPlayerAlive(i))
			++alive;
	}
 
	CGOPrintToChatAll("{RED}Был убит: {DEFAULT}%N \n {GREEN}Живых осталось: {DEFAULT}%d", client, alive);
 
	dontBroadcast = true;
	return Plugin_Changed;
}