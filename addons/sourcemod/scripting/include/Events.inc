/**
 * This is the include file for Events
 * To check that Events is installed and running, verify that the "Events" library exists
 */

#if defined _Events_included
	#endinput
#endif
#define _Events_included

#include "CEvent.inc"

/**
 * Called after the event system is loaded.
 *
 * @noreturn
 */
forward void Events_OnEventsLoaded();

/**
 * Registers an event
 *
 * @return           	True if the event module can start, false otherwise.
 */
native bool Events_RegisterEvent();

public SharedPlugin __pl_Events = 
{
	name = "Events",
	file = "Events.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_Events_SetNTVOptional()
{
	MarkNativeAsOptional("Events_RegisterEvent");
}
#endif

