#pragma semicolon 1
#include <sdktools>
#pragma newdecls required

#define VERSION 				"0.1"
#define PREFIX 					"[HG]"
#define HIDE_RADAR_CSGO 		1<<12
#define FFADE_OUT				0x0002
#define FFADE_PURGE				0x0010
#define DEATH_COLOR_FADE		{ 0, 0, 0, 255 }

bool g_bGameCSGO = true;

char Forbidden_Commands[][] = {
    "explode",		"kill",			"coverme",		"takepoint",
    "holdpos",		"regroup",		"followme",		"takingfire",
    "go",			"fallback",		"sticktog",		"getinpos",
    "stormfront",	"report",		"roger",		"enemyspot",
    "needbackup",	"sectorclear",	"inposition",	"reportingin",
    "getout",		"negative",		"enemydown",	"spectate",
    "jointeam",		"suicide",
}, config_format[32],
	g_sRemoveEntityList[][] =  {
	"func_bomb_target", 
	"hostage_entity", 
	"func_hostage_rescue", 
	"info_hostage_spawn", 
	"func_buyzone"
};

ConVar  g_cCommands = null,
		g_cRemoveWeapons = null,
		g_cDisableRadar = null,
		g_cAliveChat = null,
		g_cRemoveBomb = null,
		g_cRemoveBuyzone = null,
		g_cRemoveHostage = null,
		g_cScreenFade = null;

public Plugin hobo = {
	author = "Hikka",
	name = "HG Manager",
	description = "manager for hunger games mod",
	version = VERSION,
	url = "",
};

public void OnPluginStart() {
	for (int i = 0; i < sizeof(Forbidden_Commands); i++) {
		AddCommandListener(ForbiddenCommands, Forbidden_Commands[i]);
	}
	
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
	
	if (g_cDisableRadar.BoolValue && GetEngineVersion() != Engine_CSGO) {
		g_bGameCSGO = false;
		HookEventEx("player_blind", Event_PlayerBlind);
	}
	
	HookEventEx("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	HookEventEx("player_death", Event_PlayerDeath);
	
	g_cCommands = CreateConVar("hg_forbidden_commands", "1", "Запретить стандартные команды? (kill, suicide, radio, и т.д)", _, true, 0.0, true, 1.0);
	g_cRemoveWeapons = CreateConVar("hg_disarm_player", "1", "Оббезоружить игрока при воскрешение? (Всё оружие)", _, true, 0.0, true, 1.0);
	g_cDisableRadar = CreateConVar("hg_disable_radar", "1", "Отключить радар?", _, true, 0.0, true, 1.0);
	g_cAliveChat = CreateConVar("hg_alive_chat", "1", "Запретить мертвым говорить в чате?", _, true, 0.0, true, 1.0);
	g_cRemoveBomb = CreateConVar("hg_remove_bomb_on_spawn", "1", "Удалить зону плента бомбы?", _, true, 0.0, true, 1.0);
	g_cRemoveBuyzone = CreateConVar("hg_remove_buyzone", "1", "Удалить зону закупки?", _, true, 0.0, true, 1.0);
	g_cRemoveHostage = CreateConVar("hg_remove_hostages", "1", "Удалить зону спасения заложников?", _, true, 0.0, true, 1.0);
	g_cScreenFade = CreateConVar("hg_screen_fade", "1", "Затемнять экран игроку если он умер?", _, true, 0.0, true, 1.0);
	
	FormatEx(config_format, sizeof(config_format), "hg_manager_%s", VERSION);
	AutoExecConfig(true, config_format);
	
	CreateTimer(1.0, OnEverySecond, _, TIMER_REPEAT);
}

public Action OnEverySecond(Handle timer) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidPlayer(i) && GetClientTeam(i) > 1) {
			//
		}
	}
}
			

public Action ForbiddenCommands(int client, const char[] command, int args) {
	if (g_cCommands.BoolValue) return Plugin_Handled;
	return Plugin_Continue;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_cRemoveWeapons.BoolValue) RemoveWeapon(client);
	if (g_cScreenFade.BoolValue) ScreenFade(client);
	
	if (g_cDisableRadar.BoolValue) {
		switch (g_bGameCSGO) {
			case true: RemoveRadarCSGO(client);
			case false: RemoveRadarOther(client);
		}
	}
}

public void Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast) {
    int client;
    if (!IsFakeClient((client = GetClientOfUserId(GetEventInt(event, "userid")))) && GetClientTeam(client) > 1)
        //CreateTimer(GetEntPropFloat(client, Prop_Send, "m_flFlashDuration"), RemoveRadar, client, TIMER_FLAG_NO_MAPCHANGE);
        RemoveRadarOther(client);
}

public Action Event_Say(int client, const char[] command, int args) {
	if (g_cAliveChat.BoolValue && !IsPlayerAlive(client)) {
		PrintToChat(client, "Мертвые не разговаривают");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

#if SOURCEMOD_V_MAJOR >= 1 && (SOURCEMOD_V_MINOR >= 8 || SOURCEMOD_V_MINOR >= 7 && SOURCEMOD_V_RELEASE >= 2)
public void OnEntityCreated(int entity, const char[] name)
#else
public int OnEntityCreated(int entity, const char[] name)
#endif
{
	for (int i = 0; i < sizeof(g_sRemoveEntityList); i++) {
		if (strcmp(name, g_sRemoveEntityList[i]) != 0) continue;

		if (g_cRemoveBomb.BoolValue && strcmp("func_bomb_target", g_sRemoveEntityList[i]) == 0)
			//AcceptEntityInput(entity, "kill");
			RemoveEdict(entity);
		else if (g_cRemoveBuyzone.BoolValue && strcmp("func_buyzone", g_sRemoveEntityList[i]) == 0)
			//AcceptEntityInput(entity, "kill");
			RemoveEdict(entity);
		else if (g_cRemoveHostage.BoolValue)
			//AcceptEntityInput(entity, "kill");
			RemoveEdict(entity);
		
		break;
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_cScreenFade.BoolValue) ScreenFade(client, FFADE_OUT, DEATH_COLOR_FADE, 2, -1);
}

stock bool RemoveWeapon(int client) {
	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		int entity = CreateEntityByName("player_weaponstrip");
		if (AcceptEntityInput(entity, "strip", client) && AcceptEntityInput(entity, "kill")) {
			return true;
		}
		return false;
	}
	return false;
}

stock void RemoveRadarCSGO(int client) {
	SetEntProp(client, Prop_Send, "m_iHideHUD", HIDE_RADAR_CSGO);
}

stock void RemoveRadarOther(int client) {
    SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 3600.0);
    SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
}

stock bool IsValidPlayer(int client) {
	if (0 < client <= MaxClients && IsClientInGame(client)) return true;
	else return false;
}

void ScreenFade(int iClient, int iFlags = FFADE_PURGE, const int iaColor[4] = {0, 0, 0, 0}, int iDuration = 0, int iHoldTime = 0) {
    Handle hScreenFade = StartMessageOne("Fade", iClient);
    if (GetUserMessageType() == UM_BitBuf){
		BfWriteShort(hScreenFade, iHoldTime * 500);
		BfWriteShort(hScreenFade, iDuration * 500);
		BfWriteShort(hScreenFade, iFlags);
		BfWriteByte(hScreenFade, iaColor[0]);
		BfWriteByte(hScreenFade, iaColor[1]);
		BfWriteByte(hScreenFade, iaColor[2]);
		BfWriteByte(hScreenFade, iaColor[3]);
	} else {
		PbSetInt(hScreenFade, "duration", iDuration * 500);
		PbSetInt(hScreenFade, "hold_time", iHoldTime * 500);
		PbSetInt(hScreenFade, "flags", iFlags);
		PbSetColor(hScreenFade, "clr", iaColor);
	}
    EndMessage();
}