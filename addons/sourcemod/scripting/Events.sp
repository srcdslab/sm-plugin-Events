#pragma semicolon 1

#include <sourcemod>
#include <multicolors>
#include <Events>

#pragma newdecls required

#define PREFIX_PLUGIN_NAME	"[Event]"
#define PREFIX_CHAT			"{green}[Event]{white}"

Handle g_hForward_OnEventsLoaded;

ArrayList g_aEvent;

bool g_bDisplayAnnouncer = true;

public Plugin myinfo =
{
	name = "[Event] Core",
	author = "maxime1907",
	description = "Event manager",
	version = "1.0",
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Events_RegisterEvent", Native_RegisterEvent);
	RegPluginLibrary("Events");
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_event", Command_Event, "Show the active events");

	RegAdminCmd("sm_eventload", Command_EventLoad, ADMFLAG_RCON, "Load or unload an event, 1 = Dont display the announce message");
	RegAdminCmd("sm_eventlist", Command_EventList, ADMFLAG_RCON, "Show a list of available events");

	g_hForward_OnEventsLoaded = CreateGlobalForward("Events_OnEventsLoaded", ET_Ignore);

	if (!g_aEvent)
		g_aEvent = new ArrayList();

	CreateForward_OnEventsLoaded();
}

public void OnPluginEnd()
{
	if (g_aEvent)
	{
		for (int i = 0; i < g_aEvent.Length; i++)
		{
			CEvent myEvent = g_aEvent.Get(i);
			myEvent.Load(false, false);
			delete myEvent;
		}
		delete g_aEvent;
	}

	CloseHandle(g_hForward_OnEventsLoaded);
}

public void OnMapEnd()
{
	for (int i = 0; i < g_aEvent.Length; i++)
	{
		CEvent myEvent = g_aEvent.Get(i);
		myEvent.Load(false, false);
	}
}

//   .d8888b.   .d88888b.  888b     d888 888b     d888        d8888 888b    888 8888888b.   .d8888b.
//  d88P  Y88b d88P" "Y88b 8888b   d8888 8888b   d8888       d88888 8888b   888 888  "Y88b d88P  Y88b
//  888    888 888     888 88888b.d88888 88888b.d88888      d88P888 88888b  888 888    888 Y88b.
//  888        888     888 888Y88888P888 888Y88888P888     d88P 888 888Y88b 888 888    888  "Y888b.
//  888        888     888 888 Y888P 888 888 Y888P 888    d88P  888 888 Y88b888 888    888     "Y88b.
//  888    888 888     888 888  Y8P  888 888  Y8P  888   d88P   888 888  Y88888 888    888       "888
//  Y88b  d88P Y88b. .d88P 888   "   888 888   "   888  d8888888888 888   Y8888 888  .d88P Y88b  d88P
//   "Y8888P"   "Y88888P"  888       888 888       888 d88P     888 888    Y888 8888888P"   "Y8888P"
//

public Action Command_Event(int client, int argc)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	eventList(client);
	return Plugin_Handled;
}

public Action Command_EventList(int client, int argc)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	eventList(client, true);
	return Plugin_Handled;
}

public Action Command_EventLoad(int client, int argc)
{
	if (argc < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_eventload <eventname> 1|0");
		return Plugin_Handled;
	}

	eventLoad(client, argc);
	return Plugin_Handled;
}

// ######## ##     ## ##    ##  ######  ######## ####  #######  ##    ##  ######  
// ##       ##     ## ###   ## ##    ##    ##     ##  ##     ## ###   ## ##    ## 
// ##       ##     ## ####  ## ##          ##     ##  ##     ## ####  ## ##       
// ######   ##     ## ## ## ## ##          ##     ##  ##     ## ## ## ##  ######  
// ##       ##     ## ##  #### ##          ##     ##  ##     ## ##  ####       ## 
// ##       ##     ## ##   ### ##    ##    ##     ##  ##     ## ##   ### ##    ## 
// ##        #######  ##    ##  ######     ##    ####  #######  ##    ##  ######

stock void eventList(int client, bool bAdvanced = false)
{
	int size = g_aEvent.Length;
	bool bEventEnabled = false;

	for (int i = 0; i < size; i++)
	{
		CEvent myEvent = g_aEvent.Get(i);
		if (myEvent.bEnabled)
			bEventEnabled = true;
	}

	if (!size || (!bAdvanced && !bEventEnabled))
	{
		CPrintToChat(client, "%s No event %s", PREFIX_CHAT, bAdvanced ? "available" : "activated");
		return;
	}

	for (int i = 0; i < size; i++)
	{
		CEvent myEvent = g_aEvent.Get(i);

		if (!bAdvanced && !myEvent.bEnabled)
			continue;

		char name[64], description[255];
		myEvent.GetName(name, sizeof(name));
		myEvent.GetDescription(description, sizeof(description));

		CPrintToChat(client, "%s {blue}%s{white}%s{white}:", PREFIX_CHAT, name, bAdvanced ? (myEvent.bEnabled ? " {lightgreen}(Enabled)" : " {red}(Disabled)") : "");
		CPrintToChat(client, "%s %s", PREFIX_CHAT, description);

		if (i + 1 < size)
			CPrintToChat(client, "%s {violet}**************************", PREFIX_CHAT);
	}
}

stock void eventLoad(int client, int argc)
{
	char eventName[64];
	GetCmdArg(1, eventName, sizeof(eventName));

	if (argc >= 2)
	{
		char showAnnounce[2];
		GetCmdArg(2, showAnnounce, sizeof(showAnnounce));

		g_bDisplayAnnouncer = !(StringToInt(showAnnounce) > 0);
	}

	bool bFound = false;
	bool bLoad;
	for (int i = 0; i < g_aEvent.Length; i++)
	{
		CEvent myEvent = g_aEvent.Get(i);

		char name[64];
		myEvent.GetName(name, sizeof(name));

		if (StrEqual(name, eventName, false))
		{
			bFound = true;
			bLoad = !myEvent.bEnabled;
			myEvent.Load(bLoad, g_bDisplayAnnouncer);
			break;
		}
	}

	if (IsValidClient(client))
		CPrintToChat(client, "%s Event {blue}%s{white} %s", PREFIX_CHAT, eventName, (bFound ? (bLoad ? "has been loaded" : "has been unloaded") : "does not exist"));
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}

//########  #######  ########  ##      ##    ###    ########  ########   ######  
//##       ##     ## ##     ## ##  ##  ##   ## ##   ##     ## ##     ## ##    ## 
//##       ##     ## ##     ## ##  ##  ##  ##   ##  ##     ## ##     ## ##       
//######   ##     ## ########  ##  ##  ## ##     ## ########  ##     ##  ######  
//##       ##     ## ##   ##   ##  ##  ## ######### ##   ##   ##     ##       ## 
//##       ##     ## ##    ##  ##  ##  ## ##     ## ##    ##  ##     ## ##    ## 
//##        #######  ##     ##  ###  ###  ##     ## ##     ## ########   ######  

public void CreateForward_OnEventsLoaded()
{
	Call_StartForward(g_hForward_OnEventsLoaded);
	Call_Finish();
}

//  888b    888        d8888 88888888888 8888888 888     888 8888888888 .d8888b.
//  8888b   888       d88888     888       888   888     888 888       d88P  Y88b
//  88888b  888      d88P888     888       888   888     888 888       Y88b.
//  888Y88b 888     d88P 888     888       888   Y88b   d88P 8888888    "Y888b.
//  888 Y88b888    d88P  888     888       888    Y88b d88P  888           "Y88b.
//  888  Y88888   d88P   888     888       888     Y88o88P   888             "888
//  888   Y8888  d8888888888     888       888      Y888P    888       Y88b  d88P
//  888    Y888 d88P     888     888     8888888     Y8P     8888888888 "Y8888P"

public int Native_RegisterEvent(Handle plugin, int numParams)
{
	CEvent myEvent = null;
	char buffer[512], filename[256], name[64], description[512];

	if (!g_aEvent)
		g_aEvent = new ArrayList();

	if (GetPluginInfo(plugin, PlInfo_Name, buffer, sizeof(buffer)))
	{
		TrimString(buffer);
		int posPrefix = StrContains(buffer, PREFIX_PLUGIN_NAME, false);
		if (posPrefix >= 0)
			posPrefix = posPrefix + strlen(PREFIX_PLUGIN_NAME);
		else
			posPrefix = 0;

		Format(name, sizeof(name), "%s", buffer[posPrefix]);

		TrimString(name);
	}
	else
		Format(name, sizeof(name), "Event_%d", GetRandomInt(0, 1000));

	for (int i = 0; i < g_aEvent.Length; i++)
	{
		CEvent myEventRegistered = g_aEvent.Get(i);
		char eventName[64];
		myEventRegistered.GetName(eventName, sizeof(eventName));
		if (StrEqual(eventName, name, false))
		{
			if (myEventRegistered.bEnabled)
				return 1;
			myEvent = myEventRegistered;
			break;
		}
	}

	if (!myEvent)
	{
		GetPluginFilename(plugin, filename, sizeof(filename));

		if (!GetPluginInfo(plugin, PlInfo_Description, description, sizeof(description)))
			description = "No description available";

		myEvent = new CEvent(filename, name, description);

		g_aEvent.Push(myEvent);
	}

	myEvent.Load(false, false);

	return 0;
}