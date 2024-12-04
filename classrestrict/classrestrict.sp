#include <sourcemod>

#include <sdktools>
#include <tf2c>

#pragma semicolon 1
#pragma tabsize 4
#pragma newdecls required

#define PL_VERSION "0.7.0-AndrewB"

#define TF_CLASS_UNKNOWN		0
#define TF_CLASS_SCOUT			1
#define TF_CLASS_SNIPER			2
#define TF_CLASS_SOLDIER		3
#define TF_CLASS_DEMOMAN		4
#define TF_CLASS_MEDIC			5
#define TF_CLASS_HEAVY			6
#define TF_CLASS_PYRO			7
#define TF_CLASS_SPY			8
#define TF_CLASS_ENGINEER		9
#define TF_CLASS_CIVILIAN		10

#define TF_TEAM_RED				2
#define TF_TEAM_BLU				3
#define TF_TEAM_GRN				4
#define TF_TEAM_YLW				5

public Plugin myinfo =
{
	name        = "TF2 Class Restrictions",
	author      = "Tsunami, TF2C support added by Andrew Betson",
	description = "Restrict classes",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

int gClass[ MAXPLAYERS + 1 ];

ConVar gCVarEnabled;
ConVar gCVarFlags;
ConVar gCVarImmunity;
ConVar gCVarLimits[ 6 ][ 11 ];

char gDenialSounds[ 11 ][ 24 ] =
{	"",
	"vo/scout_no03.wav",   "vo/sniper_no04.wav", "vo/soldier_no01.wav",
	"vo/demoman_no03.wav", "vo/medic_no03.wav",  "vo/heavy_no02.wav",
	"vo/pyro_no01.wav",    "vo/spy_no02.wav",    "vo/engineer_no03.wav",
	"vo/civilian_no04.wav"
};

public void OnPluginStart()
{
	CreateConVar( "sm_classrestrict_version", PL_VERSION, "Restrict classes", FCVAR_NOTIFY );

	gCVarEnabled	= CreateConVar( "sm_classrestrict_enabled",       "1",  "Enable/disable restricting classes" );
	gCVarFlags		= CreateConVar( "sm_classrestrict_flags",         "",   "Admin flags for restricted classes" );
	gCVarImmunity	= CreateConVar( "sm_classrestrict_immunity",      "0",  "Enable/disable admins being immune for restricted classes" );

	gCVarLimits[ TF_TEAM_RED ][ TF_CLASS_SCOUT ]	= CreateConVar( "sm_classrestrict_red_scouts",    "-1", "Limit for RED Scouts" );
	gCVarLimits[ TF_TEAM_RED ][ TF_CLASS_SNIPER ]	= CreateConVar( "sm_classrestrict_red_snipers",   "-1", "Limit for RED Snipers" );
	gCVarLimits[ TF_TEAM_RED ][ TF_CLASS_SOLDIER ]	= CreateConVar( "sm_classrestrict_red_soldiers",  "-1", "Limit for RED Soldiers" );
	gCVarLimits[ TF_TEAM_RED ][ TF_CLASS_DEMOMAN ]	= CreateConVar( "sm_classrestrict_red_demomen",   "-1", "Limit for RED Demomen" );
	gCVarLimits[ TF_TEAM_RED ][ TF_CLASS_MEDIC ]	= CreateConVar( "sm_classrestrict_red_medics",    "-1", "Limit for RED Medics" );
	gCVarLimits[ TF_TEAM_RED ][ TF_CLASS_HEAVY ]	= CreateConVar( "sm_classrestrict_red_heavies",   "-1", "Limit for RED Heavies" );
	gCVarLimits[ TF_TEAM_RED ][ TF_CLASS_PYRO ]		= CreateConVar( "sm_classrestrict_red_pyros",     "-1", "Limit for RED Pyros" );
	gCVarLimits[ TF_TEAM_RED ][ TF_CLASS_SPY ]		= CreateConVar( "sm_classrestrict_red_spies",     "-1", "Limit for RED Spies" );
	gCVarLimits[ TF_TEAM_RED ][ TF_CLASS_ENGINEER ]	= CreateConVar( "sm_classrestrict_red_engineers", "-1", "Limit for RED Engineers" );

	gCVarLimits[ TF_TEAM_BLU ][ TF_CLASS_SCOUT ]	= CreateConVar( "sm_classrestrict_blu_scouts",    "-1", "Limit for BLU Scouts" );
	gCVarLimits[ TF_TEAM_BLU ][ TF_CLASS_SNIPER ]	= CreateConVar( "sm_classrestrict_blu_snipers",   "-1", "Limit for BLU Snipers" );
	gCVarLimits[ TF_TEAM_BLU ][ TF_CLASS_SOLDIER ]	= CreateConVar( "sm_classrestrict_blu_soldiers",  "-1", "Limit for BLU Soldiers" );
	gCVarLimits[ TF_TEAM_BLU ][ TF_CLASS_DEMOMAN ]	= CreateConVar( "sm_classrestrict_blu_demomen",   "-1", "Limit for BLU Demomen" );
	gCVarLimits[ TF_TEAM_BLU ][ TF_CLASS_MEDIC ]	= CreateConVar( "sm_classrestrict_blu_medics",    "-1", "Limit for BLU Medics" );
	gCVarLimits[ TF_TEAM_BLU ][ TF_CLASS_HEAVY ]	= CreateConVar( "sm_classrestrict_blu_heavies",   "-1", "Limit for BLU Heavies" );
	gCVarLimits[ TF_TEAM_BLU ][ TF_CLASS_PYRO ]		= CreateConVar( "sm_classrestrict_blu_pyros",     "-1", "Limit for BLU Pyros" );
	gCVarLimits[ TF_TEAM_BLU ][ TF_CLASS_SPY ]		= CreateConVar( "sm_classrestrict_blu_spies",     "-1", "Limit for BLU Spies" );
	gCVarLimits[ TF_TEAM_BLU ][ TF_CLASS_ENGINEER ]	= CreateConVar( "sm_classrestrict_blu_engineers", "-1", "Limit for BLU Engineers" );

	gCVarLimits[ TF_TEAM_RED ][ TF_CLASS_CIVILIAN ]	= CreateConVar( "sm_classrestrict_red_civilians", "-1", "Limit for RED Civilians" );
	gCVarLimits[ TF_TEAM_BLU ][ TF_CLASS_CIVILIAN ]	= CreateConVar( "sm_classrestrict_blu_civilians", "-1", "Limit for BLU Civilians" );
	gCVarLimits[ TF_TEAM_GRN ][ TF_CLASS_CIVILIAN ]	= CreateConVar( "sm_classrestrict_grn_civilians", "-1", "Limit for GRN Civilians" );
	gCVarLimits[ TF_TEAM_YLW ][ TF_CLASS_CIVILIAN ]	= CreateConVar( "sm_classrestrict_ylw_civilians", "-1", "Limit for YLW Civilians" );

	gCVarLimits[ TF_TEAM_GRN ][ TF_CLASS_SCOUT ]	= CreateConVar( "sm_classrestrict_grn_scouts",    "-1", "Limit for GRN Scouts" );
	gCVarLimits[ TF_TEAM_GRN ][ TF_CLASS_SNIPER ]	= CreateConVar( "sm_classrestrict_grn_snipers",   "-1", "Limit for GRN Snipers" );
	gCVarLimits[ TF_TEAM_GRN ][ TF_CLASS_SOLDIER ]	= CreateConVar( "sm_classrestrict_grn_soldiers",  "-1", "Limit for GRN Soldiers" );
	gCVarLimits[ TF_TEAM_GRN ][ TF_CLASS_DEMOMAN ]	= CreateConVar( "sm_classrestrict_grn_demomen",   "-1", "Limit for GRN Demomen" );
	gCVarLimits[ TF_TEAM_GRN ][ TF_CLASS_MEDIC ]	= CreateConVar( "sm_classrestrict_grn_medics",    "-1", "Limit for GRN Medics" );
	gCVarLimits[ TF_TEAM_GRN ][ TF_CLASS_HEAVY ]	= CreateConVar( "sm_classrestrict_grn_heavies",   "-1", "Limit for GRN Heavies" );
	gCVarLimits[ TF_TEAM_GRN ][ TF_CLASS_PYRO ]		= CreateConVar( "sm_classrestrict_grn_pyros",     "-1", "Limit for GRN Pyros" );
	gCVarLimits[ TF_TEAM_GRN ][ TF_CLASS_SPY ]		= CreateConVar( "sm_classrestrict_grn_spies",     "-1", "Limit for GRN Spies" );
	gCVarLimits[ TF_TEAM_GRN ][ TF_CLASS_ENGINEER ]	= CreateConVar( "sm_classrestrict_grn_engineers", "-1", "Limit for GRN Engineers" );

	gCVarLimits[ TF_TEAM_YLW ][ TF_CLASS_SCOUT ]	= CreateConVar( "sm_classrestrict_ylw_scouts",    "-1", "Limit for YLW Scouts" );
	gCVarLimits[ TF_TEAM_YLW ][ TF_CLASS_SNIPER ]	= CreateConVar( "sm_classrestrict_ylw_snipers",   "-1", "Limit for YLW Snipers" );
	gCVarLimits[ TF_TEAM_YLW ][ TF_CLASS_SOLDIER ]	= CreateConVar( "sm_classrestrict_ylw_soldiers",  "-1", "Limit for YLW Soldiers" );
	gCVarLimits[ TF_TEAM_YLW ][ TF_CLASS_DEMOMAN ]	= CreateConVar( "sm_classrestrict_ylw_demomen",   "-1", "Limit for YLW Demomen" );
	gCVarLimits[ TF_TEAM_YLW ][ TF_CLASS_MEDIC ]	= CreateConVar( "sm_classrestrict_ylw_medics",    "-1", "Limit for YLW Medics" );
	gCVarLimits[ TF_TEAM_YLW ][ TF_CLASS_HEAVY ]	= CreateConVar( "sm_classrestrict_ylw_heavies",   "-1", "Limit for YLW Heavies" );
	gCVarLimits[ TF_TEAM_YLW ][ TF_CLASS_PYRO ]		= CreateConVar( "sm_classrestrict_ylw_pyros",     "-1", "Limit for YLW Pyros" );
	gCVarLimits[ TF_TEAM_YLW ][ TF_CLASS_SPY ]		= CreateConVar( "sm_classrestrict_ylw_spies",     "-1", "Limit for YLW Spies" );
	gCVarLimits[ TF_TEAM_YLW ][ TF_CLASS_ENGINEER ]	= CreateConVar( "sm_classrestrict_ylw_engineers", "-1", "Limit for YLW Engineers" );

	HookEvent( "player_changeclass", Event_PlayerClass );
	HookEvent( "player_spawn", Event_PlayerSpawn );
	HookEvent( "player_team", Event_PlayerTeam );

	AutoExecConfig( true, "classrestrict" );
}

public void OnMapStart()
{
	char DenialSound[ 32 ];
	for ( int i = 1; i < sizeof( gDenialSounds ); i++ )
	{
		Format( DenialSound, sizeof( DenialSound ), "sound/%s", gDenialSounds[ i ] );
		PrecacheSound( gDenialSounds[ i ] );
		AddFileToDownloadsTable( DenialSound );
	}
}

public void OnClientPutInServer( int Client )
{
	gClass[ Client ] = TF_CLASS_UNKNOWN;
}

public void Event_PlayerClass( Event Evt, const char[] Name, bool bDontBroadcast )
{
	int Client = GetClientOfUserId( Evt.GetInt( "userid" ) );
	int Class = Evt.GetInt( "class" );
	int Team = GetClientTeam( Client );

	if ( !( gCVarImmunity.BoolValue && IsImmune( Client ) ) && IsFull( Team, Class ) )
	{
		char TeamClassname[ 13 ];
		GetTeamClassname( Team, TeamClassname, sizeof( TeamClassname ) );

		ShowVGUIPanel( Client, TeamClassname );
		EmitSoundToClient( Client, gDenialSounds[ Class ] );
		TF2_SetPlayerClass( Client, view_as< TFClassType >( gClass[ Client ] ) );
	}
}

public void Event_PlayerSpawn(Event Evt, const char[] Name, bool bDontBroadcast)
{
	int Client = GetClientOfUserId( Evt.GetInt( "userid" ) );
	int Team = GetClientTeam( Client );

	if ( !( gCVarImmunity.BoolValue && IsImmune( Client ) ) && IsFull( Team, ( gClass[ Client ] = view_as< int >( TF2_GetPlayerClass( Client ) ) ) ) )
	{
		char TeamClassname[ 13 ];
		GetTeamClassname( Team, TeamClassname, sizeof( TeamClassname ) );

		ShowVGUIPanel( Client, TeamClassname );
		EmitSoundToClient( Client, gDenialSounds[ gClass[ Client ] ] );
		PickClass( Client );
	}
}

public void Event_PlayerTeam(Event Evt, const char[] Name, bool bDontBroadcast)
{
	int Client = GetClientOfUserId( Evt.GetInt( "userid" ) );
	int Team = Evt.GetInt( "team" );

	if ( !( gCVarImmunity.BoolValue && IsImmune( Client ) ) && IsFull( Team, gClass[ Client ] ) )
	{
		char TeamClassname[ 13 ];
		GetTeamClassname( Team, TeamClassname, sizeof( TeamClassname ) );

		ShowVGUIPanel( Client, TeamClassname );
		EmitSoundToClient( Client, gDenialSounds[ gClass[ Client ] ] );
		PickClass( Client );
	}
}

void GetTeamClassname( int Team, char[] Buffer, int BufferLen )
{
	switch ( Team )
	{
		case TF_TEAM_BLU: strcopy( Buffer, BufferLen, "class_blue" );
		case TF_TEAM_RED: strcopy( Buffer, BufferLen, "class_red" );
		case TF_TEAM_GRN: strcopy( Buffer, BufferLen, "class_green" );
		case TF_TEAM_YLW: strcopy( Buffer, BufferLen, "class_yellow" );
		default: strcopy( Buffer, BufferLen, "class_none" );
	}
}

bool IsFull( int Team, int Class )
{
	// If plugin is disabled, or team or class is invalid, class is not full
	if ( !gCVarEnabled.BoolValue || Team < TF_TEAM_RED || Class < TF_CLASS_SCOUT )
	{
		return false;
	}

	// Get team's class limit
	int Limit = gCVarLimits[ Team ][ Class ].IntValue;

	// If limit is -1, class is not full
	if ( Limit == -1 )
	{
		return false;
	}

	// If limit is 0, class is full
	else if ( Limit == 0 )
	{
		return true;
	}

	// Loop through all Clients
	for ( int i = 1, Count = 0; i <= MaxClients; i++ )
	{
		// If Client is in game, on this team, has this class and limit has been reached, class is full
		if ( IsClientInGame( i ) && GetClientTeam( i ) == Team && view_as< int >( TF2_GetPlayerClass( i ) ) == Class && ++Count > Limit )
		{
			return true;
		}
	}

	return false;
}

bool IsImmune( int Client )
{
	if ( !Client || !IsClientInGame( Client ) )
	{
		return false;
	}

	char Flags[ 32 ];
	gCVarFlags.GetString( Flags, sizeof( Flags ) );

	// If flags are specified and Client has generic or root flag, Client is immune
	return !StrEqual( Flags, "" ) && CheckCommandAccess( Client, "classrestrict", ReadFlagString( Flags ) );
}

void PickClass( int Client )
{
	// Loop through all classes, starting at random class
	for ( int i = GetRandomInt( TF_CLASS_SCOUT, TF_CLASS_ENGINEER ), Class = i, Team = GetClientTeam( Client ) ;; )
	{
		// If team's class is not full, set Client's class
		if ( !IsFull( Team, i ) )
		{
			TF2_SetPlayerClass( Client, view_as< TFClassType >( i ) );
			TF2_RespawnPlayer( Client );
			gClass[ Client ] = i;
			break;
		}

		// If next class index is invalid, start at first class
		else if ( ++i > TF_CLASS_ENGINEER )
		{
			i = TF_CLASS_SCOUT;
		}

		// If loop has finished, stop searching
		else if ( i == Class )
		{
			break;
		}
	}
}
