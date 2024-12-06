#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

ConVar g_cvarEnabled;
ConVar g_cvarVoice;
ConVar g_cvarConnect;
ConVar g_cvarDisconnect;
ConVar g_cvarChangeClass;
ConVar g_cvarTeam;
ConVar g_cvarArenaResize;
ConVar g_cvarArenaMaxStreak;
ConVar g_cvarCvar;
ConVar g_cvarAllText;

ConVar g_cvarActivateMsg;

#define PLUGIN_VERSION "0.6-AndrewB"
public Plugin myinfo = 
{
	name = "Tidy Chat",
	author = "linux_lover, TF2C support and modifications by Andrew Betson",
	description = "Cleans up the chat area.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=101340",
};

public void OnPluginStart()
{
	CreateConVar("sm_tidychat_version", PLUGIN_VERSION, "Tidy Chat Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_cvarEnabled = CreateConVar("sm_tidychat_on", "1", "0/1 On/off");
	g_cvarVoice = CreateConVar("sm_tidychat_voice", "1", "0/1 Tidy (Voice) messages");
	g_cvarConnect = CreateConVar("sm_tidychat_connect", "0", "0/1 Tidy connect messages");
	g_cvarDisconnect = CreateConVar("sm_tidychat_disconnect", "0", "0/1 Tidy disconnect messsages");
	g_cvarChangeClass = CreateConVar("sm_tidychat_class", "1", "0/1 Tidy class change messages");
	g_cvarTeam = CreateConVar("sm_tidychat_team", "1", "0/1 Tidy team join messages");
	g_cvarArenaResize = CreateConVar("sm_tidychat_arena_resize", "1", "0/1 Tidy arena team resize messages");
	g_cvarArenaMaxStreak = CreateConVar("sm_tidychat_arena_maxstreak", "1", "0/1 Tidy (arena) team scramble messages");
	g_cvarCvar = CreateConVar("sm_tidychat_cvar", "1", "0/1 Tidy cvar messages");
	g_cvarAllText = CreateConVar("sm_tidychat_alltext", "0", "0/1 Tidy all chat messages from plugins");

	g_cvarActivateMsg = CreateConVar("sm_tidychat_activatemsg", "1", "0/1 Print custom join message when players fully connect");

	// Mod independant hooks
	HookEvent("player_connect_client", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent( "player_activate", Event_PlayerActivate, EventHookMode_Post );
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("server_cvar", Event_Cvar, EventHookMode_Pre);
	HookUserMessage(GetUserMessageId("TextMsg"), UserMsg_TextMsg, true);

	HookUserMessage(GetUserMessageId("VoiceSubtitle"), UserMsg_VoiceSubtitle, true);
	HookEvent("arena_match_maxstreak", Event_MaxStreak, EventHookMode_Pre);

	AutoExecConfig( true, "tidychat" );
}

public Action Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast)
{
	if(g_cvarEnabled.BoolValue && g_cvarConnect.BoolValue)
	{
		event.BroadcastDisabled = true;
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	if(g_cvarEnabled.BoolValue && g_cvarDisconnect.BoolValue)
	{
		event.BroadcastDisabled = true;
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerActivate( Event Evt, const char[] Name, bool bDontBroadcast )
{
	if ( g_cvarEnabled.BoolValue && ( g_cvarConnect.BoolValue && g_cvarActivateMsg.BoolValue ) )
	{
		int Client = GetClientOfUserId( Evt.GetInt( "userid" ) );

		// Icky, no-good hack!
		RequestFrame( Frame_PrintActivatedPlayerName, Client );
	}

	return Plugin_Continue;
}

void Frame_PrintActivatedPlayerName( any Data )
{
	int Client = view_as< int >( Data );

	char ClientName[ MAX_NAME_LENGTH ];
	GetClientName( Client, ClientName, sizeof( ClientName ) );

	char ClientAuthId[ MAX_AUTHID_LENGTH ];
	GetClientAuthId( Client, AuthId_Steam2, ClientAuthId, sizeof( ClientAuthId ), true );

	PrintToChatAll( "%s (%s) has joined the game", ClientName, ClientAuthId );
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if(g_cvarEnabled.BoolValue && g_cvarTeam.BoolValue)
	{
		if(!event.GetBool("silent"))
		{
			event.BroadcastDisabled = true;
		}
	}
	
	return Plugin_Continue;
}

public Action Event_MaxStreak(Event event, const char[] name, bool dontBroadcast)
{
	if(g_cvarEnabled.BoolValue && g_cvarArenaMaxStreak.BoolValue)
	{
		event.BroadcastDisabled = true;
	}
	
	return Plugin_Continue;
}

public Action Event_Cvar(Event event, const char[] name, bool dontBroadcast)
{
	if(g_cvarEnabled.BoolValue && g_cvarCvar.BoolValue)
	{
		event.BroadcastDisabled = true;
	}
	
	return Plugin_Continue;
}

public Action UserMsg_VoiceSubtitle(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if(g_cvarEnabled.BoolValue && g_cvarVoice.BoolValue)
	{
		msg.ReadByte();
		int VSMenu = msg.ReadByte();
		int VSItem = msg.ReadByte();

		// Allow the Spy! and ÜberCharge % voice subtitles
		if ( ( VSMenu == 1 && ( VSItem == 1 || VSItem == 7 ) ) )
		{
			return Plugin_Continue;
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action UserMsg_TextMsg(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if(g_cvarEnabled.BoolValue)
	{
		if(g_cvarAllText.BoolValue) return Plugin_Handled;

		char message[32];
		msg.ReadByte();
		msg.ReadString(message, sizeof(message));

		if(g_cvarChangeClass.BoolValue && (strcmp(message, "#game_respawn_as") == 0 || strcmp(message, "#game_spawn_as") == 0))
		{
			return Plugin_Handled;
		}

		if(g_cvarArenaResize.BoolValue && strncmp(message, "#TF_Arena_TeamSize", 18) == 0) // #TF_Arena_TeamSizeIncreased/Decreased
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}
