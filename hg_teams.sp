#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <CustomPlayerSkins>

#define PLUGIN_VERSION "1.0.0.0"
public Plugin:myinfo =
{
	name 		= "[CS:GO] Hunger Games Teams",
	author 		= "AlexTheRegent",
	description = "teams for hunger games mod",
	version 	= PLUGIN_VERSION,
	url 		= "https://github.com/alextheregent/hungergames"
}

StringMap	g_hTrie_TeamNameFromUserId;
StringMap	g_hTrie_TeamsNames;
ArrayList	g_hArray_Teams;
bool		g_bTeamLeader[MAXPLAYERS+1];
int			g_iChatStatus[MAXPLAYERS+1];
int			g_iCurrentTeam;
int			g_iDesiredTeam[MAXPLAYERS+1];
int			g_iTeam[MAXPLAYERS+1];
int			g_iSkin[MAXPLAYERS+1];

public OnPluginStart() 
{
	g_hTrie_TeamNameFromUserId = new StringMap();
	g_hTrie_TeamsNames = new StringMap();
	g_hArray_Teams = new ArrayList(16);
	
	HookEvent("player_death", Ev_PlayerDeath);
	
	// CS:GO Admin ESP by Root
	HookEvent("player_spawn", OnPlayerEvents, EventHookMode_Post);
	// end of CS:GO Admin ESP by Root
	
	RegConsoleCmd("sm_teams", Command_Teams);
}

public OnMapStart() 
{
	g_hTrie_TeamNameFromUserId.Clear();
	g_hTrie_TeamsNames.Clear();
	g_hArray_Teams.Clear();
	g_iCurrentTeam = 1;
}

public OnConfigsExecuted() 
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		g_iDesiredTeam[i] = 0;
		g_iTeam[i] = 0;
	}
}

public OnClientPutInServer(int iClient)
{
	CS_SetClientClanTag(iClient, "");
	g_iDesiredTeam[iClient] = 0;
	g_iTeam[iClient] = 0;
	
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if ( g_iTeam[attacker] != 0 && g_iTeam[victim] == g_iTeam[attacker] )
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnClientDisconnect(int iClient)
{
	if ( g_bTeamLeader[iClient] )
	{
		DismissTeam(iClient);
	}
	else if ( g_iTeam[iClient] )
	{
		g_iTeam[iClient] = 0;
	}
	g_iDesiredTeam[iClient] = 0;
	g_iSkin[iClient] = 0;
}

public Ev_PlayerDeath(Handle hEvent, const char[] szEvName, bool bDontBroadcast)
{
	int iTeams = 0, iTeam, iBuffer;
	for ( int i = 1; i <= MaxClients; ++i )
	{
		if ( IsClientInGame(i) && IsPlayerAlive(i) )
		{
			if ( g_iTeam[i] )
			{
				if ( iTeam != g_iTeam[i] )
				{
					iBuffer = i;
					iTeam = g_iTeam[i];
					iTeams++;
				}
			}
			else iTeams++;
		}
	}
	
	if ( iTeam && iTeams == 1 )
	{
		char szBuffer[16]; GetClientTeamName(iBuffer, szBuffer, sizeof(szBuffer));
		CS_TerminateRound(3.0, CSRoundEnd_Draw);
		PrintCenterTextAll("Выиграла команда: %s", szBuffer);
	}
}

public Action Command_Teams(int iClient, int iArgs)
{
	DisplayTeamMenu(iClient);
	return Plugin_Handled;
}

void DisplayTeamMenu(int iClient)
{
	Menu hMenu = new Menu(Handle_TeamsMenu);
	hMenu.SetTitle("Управление командой:\n ");
	hMenu.AddItem("create", 	"Создать команду");
	hMenu.AddItem("join", 		"Вступить в команду");
	hMenu.AddItem("approve", 	"Принять в команду");
	hMenu.AddItem("leave", 		"Покинуть команду");
	hMenu.AddItem("dismiss", 	"Распустить команду");
	hMenu.AddItem("kick", 		"Выгнать из команды");
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public Handle_TeamsMenu(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	if ( action == MenuAction_Select )
	{
		char szInfo[16]; hMenu.GetItem(iSlot, szInfo, sizeof(szInfo));
		if ( StrEqual(szInfo, "create") )
		{
			if ( !g_iTeam[iClient] )
			{
				Panel hPanel = new Panel();
				hPanel.SetTitle("Создание команды:\n ");
				hPanel.DrawText("Введите название команды (до 10 символов)");
				hPanel.Send(iClient, Handle_EmptyPanel, MENU_TIME_FOREVER);
				g_iChatStatus[iClient] = 1;
			}
			else
			{
				PrintToChat(iClient, "Вы уже состоите в команде");
				DisplayTeamMenu(iClient);
			}
		}
		else if ( StrEqual(szInfo, "join") )
		{
			if ( !g_iTeam[iClient] )
			{
				Menu hTeamsMenu = new Menu(Handle_JoinTeam);
				hTeamsMenu.SetTitle("Выберите команду для вступления:\n ");
				
				char szTeamName[16];
				int iTeamsCount = g_hArray_Teams.Length;
				for ( int iTeam = 0; iTeam < iTeamsCount; ++iTeam )
				{
					g_hArray_Teams.GetString(iTeam, szTeamName, sizeof(szTeamName));
					hTeamsMenu.AddItem(szTeamName, szTeamName);
				}
				
				if ( hTeamsMenu.ItemCount == 0 )
				{
					hTeamsMenu.AddItem(NULL_STRING, "На данный момент нет команд", ITEMDRAW_DISABLED);
				}
				hTeamsMenu.Display(iClient, MENU_TIME_FOREVER);
			}
			else
			{
				PrintToChat(iClient, "Вы уже состоите в команде");
				DisplayTeamMenu(iClient);
			}
		}
		else if ( StrEqual(szInfo, "approve") )
		{
			if ( g_bTeamLeader[iClient] && g_iTeam[iClient] )
			{
				Menu hApproveMenu = new Menu(Handle_ApproveMenu);
				hApproveMenu.SetTitle("Список кандидатов:\n ");
				
				char szBuffer[8], szName[32];
				for ( int i = 1; i < MaxClients; ++i )
				{
					if ( g_iDesiredTeam[i] == g_iTeam[iClient] )
					{
						GetClientName(i, szName, sizeof(szName));
						IntToString(GetClientUserId(i), szBuffer, sizeof(szBuffer));
						hApproveMenu.AddItem(szBuffer, szName);
					}
				}
				
				if ( hApproveMenu.ItemCount == 0 )
				{
					hApproveMenu.AddItem(NULL_STRING, "На данный момент никто не подал заявку", ITEMDRAW_DISABLED);
				}
				hApproveMenu.Display(iClient, MENU_TIME_FOREVER);
			}
			else
			{
				PrintToChat(iClient, "Вы не являетесь главой команды");
				DisplayTeamMenu(iClient);
			}
		}
		else if ( StrEqual(szInfo, "leave") )
		{
			if ( g_iTeam[iClient] )
			{
				if ( g_bTeamLeader[iClient] )
				{
					PrintToChat(iClient, "Глава команды не может покинуть команду. Используйте \"распустить команду\"");
					DisplayTeamMenu(iClient);
				}
				else
				{
					CS_SetClientClanTag(iClient, "");
					PrintToChat(iClient, "Вы покинули команду");
					g_iTeam[iClient] = 0;
					DisplayTeamMenu(iClient);
				}
			}
			else 
			{
				PrintToChat(iClient, "Вы не состоите в команде");
				DisplayTeamMenu(iClient);
			}
		}
		else if ( StrEqual(szInfo, "dismiss") )
		{
			if ( g_bTeamLeader[iClient] )
			{
				DismissTeam(iClient);
			}
			else
			{
				PrintToChat(iClient, "Вы не являетесь главой команды");
				DisplayTeamMenu(iClient);
			}
		}
		else if ( StrEqual(szInfo, "kick") )
		{
			if ( g_bTeamLeader[iClient] )
			{
				Menu hKickMenu = new Menu(Handle_KickMenu);
				hKickMenu.SetTitle("Список команды:\n ");
				
				char szBuffer[8], szName[32];
				for ( int i = 1; i < MaxClients; ++i )
				{
					if ( g_iTeam[i] == g_iTeam[iClient] && !g_bTeamLeader[i] )
					{
						GetClientName(i, szName, sizeof(szName));
						IntToString(GetClientUserId(i), szBuffer, sizeof(szBuffer));
						hKickMenu.AddItem(szBuffer, szName);
					}
				}
				
				if ( hKickMenu.ItemCount == 0 )
				{
					hKickMenu.AddItem(NULL_STRING, "В команде нет игроков", ITEMDRAW_DISABLED);
				}
				hKickMenu.Display(iClient, MENU_TIME_FOREVER);
			}
			else
			{
				PrintToChat(iClient, "Вы не являетесь главой команды");
				DisplayTeamMenu(iClient);
			}
		}
	}
	else if ( action == MenuAction_End )
	{
		CloseHandle(hMenu);
	}
}

DismissTeam(int iClient)
{
	for ( int i = 1; i <= MaxClients; ++i )
	{
		if ( g_iTeam[i] == g_iTeam[iClient] && !g_bTeamLeader[i] )
		{
			CS_SetClientClanTag(i, "");
			PrintToChat(i, "Глава распустил команду");
			g_iTeam[i] = 0;
		}
	}
	
	char szTeamName[16];
	if ( GetClientTeamName(iClient, szTeamName, sizeof(szTeamName)) )
	{
		int iIndex = FindStringInArray(g_hArray_Teams, szTeamName);
		if ( iIndex != -1 )
		{
			g_hArray_Teams.Erase(iIndex);
			RemoveFromTrie(g_hTrie_TeamsNames, szTeamName);
		}
		else
		{
			LogError("GetClientTeamName() == true; FindStringInArray() == -1");
		}
	}
	
	CS_SetClientClanTag(iClient, "");
	PrintToChat(iClient, "Вы распустили команду");
	g_bTeamLeader[iClient] = false;
	g_iTeam[iClient] = 0;
}

bool GetClientTeamName(int iClient, char[] szTeamName, int iMaxLen)
{
	char szBuffer[16]; IntToString(GetClientUserId(iClient), szBuffer, sizeof(szBuffer));
	return g_hTrie_TeamNameFromUserId.GetString(szBuffer, szTeamName, iMaxLen);
}

public Handle_JoinTeam(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	if ( action == MenuAction_Select )
	{
		char szInfo[16]; hMenu.GetItem(iSlot, szInfo, sizeof(szInfo));
		int iBuffer;
		if ( g_hTrie_TeamsNames.GetValue(szInfo, iBuffer) )
		{
			g_iDesiredTeam[iClient] = iBuffer;
			for ( int i = 1; i <= MaxClients; ++i )
			{
				if ( g_bTeamLeader[i] && g_iTeam[i] == iBuffer )
				{
					PrintToChat(i, "Игрок %N хочет вступить в вашу команду", iClient);
					break;
				}
			}
		}
		else
		{
			PrintToChat(iClient, "Выбранная команда не найдена");
		}
	}
	else if ( action == MenuAction_End )
	{
		CloseHandle(hMenu);
	}
}

public Handle_ApproveMenu(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	if ( action == MenuAction_Select )
	{
		if ( g_bTeamLeader[iClient] )
		{
			char szInfo[16]; hMenu.GetItem(iSlot, szInfo, sizeof(szInfo));
			int iTarget = GetClientOfUserId(StringToInt(szInfo));
			
			if ( iTarget && g_iDesiredTeam[iTarget] == g_iTeam[iClient] )
			{
				if ( GetMembersCount(g_iTeam[iClient]) < 3 )
				{
					g_iDesiredTeam[iTarget] = 0;
					g_iTeam[iTarget] = g_iTeam[iClient];
					PrintToChat(iTarget, "%N одобрил вашу заявку на вступление в команду", iClient);
					PrintToChat(iClient, "Вы приняли %N в ваш отряд", iTarget);
					
					char szBuffer[16], szTeamName[16]; IntToString(GetClientUserId(iTarget), szBuffer, sizeof(szBuffer));
					GetClientTeamName(iClient, szTeamName, sizeof(szTeamName));
					g_hTrie_TeamNameFromUserId.SetString(szBuffer, szTeamName);
					CS_SetClientClanTag(iTarget, szTeamName);
				}
				else
				{
					PrintToChat(iClient, "В команде не может быть больше двух игроков");
				}
			}
			else
			{
				PrintToChat(iClient, "Не удалось одобрить заявку");
			}
			
			DisplayTeamMenu(iClient);
		}
		else
		{
			PrintToChat(iClient, "Ошибка: вы не являетесь главой команды");
		}
	}
	else if ( action == MenuAction_End )
	{
		CloseHandle(hMenu);
	}
}

GetMembersCount(int iTeam)
{
	int iCount = 0;
	for ( int i = 1; i <= MaxClients; ++i )
	{
		if ( g_iTeam[i] == iTeam && !g_bTeamLeader[i] )
		{
			iCount++;
		}
	}
	return iCount;
}

public Handle_KickMenu(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
	if ( action == MenuAction_Select )
	{
		if ( g_bTeamLeader[iClient] )
		{
			char szInfo[16]; hMenu.GetItem(iSlot, szInfo, sizeof(szInfo));
			int iTarget = GetClientOfUserId(StringToInt(szInfo));
			
			if ( iTarget && g_iTeam[iTarget] == g_iTeam[iClient] )
			{
				g_iTeam[iTarget] = 0;
				CS_SetClientClanTag(iTarget, "");
				PrintToChat(iTarget, "%N выгнал вас из команды", iClient);
			}
			else
			{
				PrintToChat(iClient, "Не удалось выгнать игрока");
			}
		}
		else
		{
			PrintToChat(iClient, "Ошибка: вы не являетесь главой команды");
		}
	}
	else if ( action == MenuAction_End )
	{
		CloseHandle(hMenu);
	}
}

public Handle_EmptyPanel(Menu hMenu, MenuAction action, int iClient, int iSlot)
{
}

public Action OnClientSayCommand(int iClient, const char[] szCommand, const char[] sArgs)
{
	if ( g_iChatStatus[iClient] )
	{
		if ( g_iChatStatus[iClient] == 1 )
		{
			int iBuffer;
			if ( g_hTrie_TeamsNames.GetValue(sArgs, iBuffer) )
			{
				PrintToChat(iClient, "Команда с таким названием существует");
				return Plugin_Handled;
			}
			if ( !IsValidTeamName(sArgs) )
			{
				PrintToChat(iClient, "В названии команды должны быть только буквы и цифры");
				return Plugin_Handled;
			}
			
			g_hArray_Teams.PushString(sArgs);
			g_hTrie_TeamsNames.SetValue(sArgs, g_iCurrentTeam);
			g_bTeamLeader[iClient] = true;
			g_iTeam[iClient] = g_iCurrentTeam++;
			
			char szBuffer[16]; IntToString(GetClientUserId(iClient), szBuffer, sizeof(szBuffer));
			g_hTrie_TeamNameFromUserId.SetString(szBuffer, sArgs);
			CS_SetClientClanTag(iClient, sArgs);
			
			PrintToChat(iClient, "Команда %s успешно создана", sArgs);
			FakeClientCommand(iClient, "menuselect 0");
			g_iChatStatus[iClient] = 0;
		}
	}
	
	return Plugin_Continue;
}

bool IsValidTeamName(const char[] szTeamName)
{
	int iLength = strlen(szTeamName);
	for ( int i = 0; i < iLength; ++i ) {
		if ( ! (szTeamName[i] >= '0' && szTeamName[i] <= '9') || (szTeamName[i] >= 'A' && szTeamName[i] <= 'Z') 
			|| (szTeamName[i] >= 'a' && szTeamName[i] <= 'z') ) {
			return false;
		}
	}
	return true;
}

// CS:GO Admin ESP by Root
public OnPlayerEvents(Event hEvent, const char [] szName, bool bDontBroadcast)
{
	int iUserId = hEvent.GetInt("userid");
	CreateTimer(0.1, Timer_SetupGlow, iUserId, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_SetupGlow(Handle:timer, any:client)
{
	// Validate client on delayed callback
	if ((client = GetClientOfUserId(client)))
	{
		decl String:model[PLATFORM_MAX_PATH];

		// Retrieve current player model
		GetClientModel(client, model, sizeof(model));

		// Remove old custom skin and create a new one with same model as player
		CPS_RemoveSkin(client); // Does not make the model invisible. (useful for glows) (c) CustomPlayerSkins.inc file
		CPS_SetSkin(client, model, CPS_RENDER);

		// Retrieve skin entity from core plugin
		new skin = CPS_GetSkin(client);

		// Validate skin entity by SDKHookEx native return
		if (SDKHookEx(skin, SDKHook_SetTransmit, OnSetTransmit))
		{
			// Declare convar strings to properly colorize players
			decl String:color[16], String:pieces[4][sizeof(color)];

			// Get values from plugin convars
			switch (GetClientTeam(client))
			{
				case CS_TEAM_T:  strcopy(color, sizeof(color), "255 0 0 255");
				case CS_TEAM_CT: strcopy(color, sizeof(color), "255 0 0 255");
			}

			// Get rid of spaces to get all the RGBA values
			if (ExplodeString(color, " ", pieces, sizeof(pieces), sizeof(pieces[])) == 4)
			{
				// Enable glow on prop_physics_override entity, aka custom player skin
				SetupGlow(skin, StringToInt(pieces[0]), StringToInt(pieces[1]), StringToInt(pieces[2]), StringToInt(pieces[3]));
			}
			
			g_iSkin[client] = skin;
		}
	}
}

SetupGlow(entity, r, g, b, a)
{
	static offset;

	// Get sendprop offset for prop_dynamic_override
	if (!offset && (offset = GetEntSendPropOffs(entity, "m_clrGlow")) == -1)
	{
		LogError("Unable to find property offset: \"m_clrGlow\"!");
		return;
	}

	// Enable glow for custom skin
	SetEntProp(entity, Prop_Send, "m_bShouldGlow", true, true);

	// So now setup given glow colors for the skin
	SetEntData(entity, offset, r, _, true);    // Red
	SetEntData(entity, offset + 1, g, _, true); // Green
	SetEntData(entity, offset + 2, b, _, true); // Blue
	SetEntData(entity, offset + 3, a, _, true); // Alpha
}

public Action:OnSetTransmit(entity, client)
{
	int iObserver;
	for ( int i = 1; i <= MaxClients; ++i )
	{
		if ( g_iSkin[i] == entity )
		{
			iObserver = i;
			break;
		}
	}
	
	// Dont show custom player skins if player is not observing/using ESP
	return ( g_iTeam[iObserver] && g_iTeam[iObserver] == g_iTeam[client]) ? Plugin_Continue : Plugin_Handled;
}
