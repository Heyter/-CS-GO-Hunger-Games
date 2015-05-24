#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_NAME "[HG] Disable scoreboard"
#define PLUGIN_AUTHOR "Mitchell"
#define PLUGIN_DESCRIPTION "Hunger Games Disable K/D on scoreboard"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL "hlmod.ru & excw.ru"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL,
};

public OnMapStart()
{
    new iEnt = -1;
    iEnt = FindEntityByClassname(iEnt, "cs_player_manager");
    if (iEnt != INVALID_ENT_REFERENCE) {
        SDKHook(iEnt, SDKHook_ThinkPost, Hook_OnThinkPost_Player);
    }
}

public Hook_OnThinkPost_Player(iEnt) {
    static iAliveOffset = -1;
    if (iAliveOffset == -1)
        iAliveOffset = FindSendPropInfo("CCSPlayerResource", "m_bAlive");
    static iKillOffset = -1;
    if (iKillOffset == -1)
        iKillOffset = FindSendPropInfo("CCSPlayerResource", "m_iKills");
    static iDeathOffset = -1;
    if (iDeathOffset == -1)
        iDeathOffset = FindSendPropInfo("CCSPlayerResource", "m_iDeaths");
    static iAssistsOffset = -1;
    if (iAssistsOffset == -1)
        iAssistsOffset = FindSendPropInfo("CCSPlayerResource", "m_iAssists");
    static iScoreOffset = -1;
    if (iScoreOffset == -1)
        iScoreOffset = FindSendPropInfo("CCSPlayerResource", "m_iScore");
    new iAlive[MAXPLAYERS+1] = {1,...};
    new iZeroes[MAXPLAYERS+1] = {0,...};
    SetEntDataArray(iEnt, iAliveOffset, iAlive, MaxClients+1);
    SetEntDataArray(iEnt, iKillOffset, iZeroes, MaxClients+1);
    SetEntDataArray(iEnt, iDeathOffset, iZeroes, MaxClients+1);
    SetEntDataArray(iEnt, iAssistsOffset, iZeroes, MaxClients+1);
    SetEntDataArray(iEnt, iScoreOffset, iZeroes, MaxClients+1);
}  
