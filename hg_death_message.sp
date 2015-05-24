#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <cstrike>

#define PLUGIN_NAME "[HG] Death Message"
#define PLUGIN_AUTHOR "Hejter & johny01"
#define PLUGIN_VERSION "1.1"
#define PLUGIN_URL "hlmod.ru & excw.ru"

#define MAX_FILE_LEN 80
new Handle:g_hKillSound = INVALID_HANDLE;
new String:g_sKillSound[MAX_FILE_LEN];
 
public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    version = PLUGIN_VERSION,
	url = PLUGIN_URL,
};
 
public OnPluginStart()
{
    HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
    HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Pre);
    g_hKillSound = CreateConVar("hg_kill_sound", "hunger_games/death/kill_sound.wav", "Звук при убийстве.");
    HookUserMessage(GetUserMessageId("TextMsg"), Hook_TextMsg, true); 

    AutoExecConfig(true, "death_message", "sourcemod/hunger_games");
}

public OnConfigsExecuted()
{
	GetConVarString(g_hKillSound, g_sKillSound, MAX_FILE_LEN);
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(g_sKillSound, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_sKillSound);
	AddFileToDownloadsTable(buffer);
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
 
        ClientCommand(i, "play %s", g_sKillSound);
 
        if(IsPlayerAlive(i))
            ++alive;
    }
 
    PrintToChatAll("%N Ушел в мир иной. %d Живых осталось", client, alive);
 
    dontBroadcast = true;
    return Plugin_Changed;
}
