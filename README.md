# RCBotSven5
New Angelscript RCBot for Svencoop 5 test

Bot currently walks around and shoot using most weapons (don't use secondary fire yet)
Imported tons of waypoints from RCBOT1 (some are corrupt... or maps have changed since)

waypoints for osprey and sc_another are working, others haven't tested

WIP!!!

# Editor

Visual Studio Code: https://code.visualstudio.com/

# Usage

save all files to svencoop/scripts/plugins/BotManager (overwrite current scripts)

open default_plugins.txt

add "BotManager" plugin

	"plugin"
	{
		"name" "RCBot"
		"script" "BotManager/BotManager"
		"concommandns" "rcbot"
	}
	
when running type

	as_command rcbot.waypoint_load

to load waypoints, and....

	as_command rcbot.addbot

to add a bot 

# Waypointing

Waypointing currently only works on listen server

# Adding a waypoint

Use the command

    as_command rcbot.waypoint_add

Paths will be created automatically between nearby waypoints, however they may be sub-optimal. So you may need to add paths manually or remove bad paths.

# Add a path

Go to the first waypoint and use the command

    as_command rcbot.pathwaypoint_create1

then go to the second waypoint and use the command:

    as_command rcbot.pathwaypoint create2

# Remove a path

Go to the first waypoint and use the command

    as_command rcbot.pathwaypoint_remove1

then go to the second waypoint and use the command:

    as_command rcbot.pathwaypoint remove2
    
   # Remove all paths to a waypoint
   
   Go to the waypoint and use the command

    as_command rcbot.pathwaypoint_remove_to

   # Remove all paths from a waypoint
   
   Go to the waypoint and use the command

    as_command rcbot.pathwaypoint_remove_from
    
# Deleting a waypoint

    as_command rcbot.waypoint_delete

# Waypoint Types

    Waypoint type	Usage										Implementation status
    "team"														unimplemented
    "teamspecific"												Unimplemented
    "crouch"		Put where bot needs to crouch (auto)		OK
    "ladder"		Coming soon									Unimplemented
    "lift"			Coming soon									Unimplemented
    "door"			Coming soon									Unimplemented
    "health"		Put at health pick up or health charger		Fully implemented
    "armor"			Put at battery pickup or HEV charger		Fully implemented
    "ammo"			Put at ammo pickup							OK (partially implemented)
    "checklift"		Coming soon									Unimplemented
    "important"		Put at objective point such as button 
					or breakable needed to move to next stage	OK
    "barney"		Coming soon									Unimplemented
    "defend"		Coming soon									Unimplemented
    "aiming"		Coming soon									Unimplemented
    "crouchjump"	Coming soon									Unimplemented
    "wait"		Bots wait 1 sec before moving to next waypoint					OK (waitlift unimplemented)
    "pain"			Put at a place where bots will be killed 
					until a trigger_hurt stops working			OK
    "jump"			Put where a bot needs to jump				OK
    "weapon"		Put at a weapon pickup						OK (partially implemented)
    "teleport"		Put at a teleport							OK
    "tank"			Coming soon									Unimplemented
    "grapple"		Coming soon									Unimplemented
    "staynear"		Coming soon									Unimplemented
    "end"			Put at the end of level (main objective)	OK
    "openslater"	Put behind an area that opens later and 
					has path between a wall/door				OK
    "humantower"	Coming soon									Unimplemented
    "unreachable"	Used for visibility only							OK
    "pushable"		Coming soon									Unimplemented
    "grenthrow"		Coming soon									Unimplemented

# Giving a waypoint a type

Walk to nearest waypoint and use the command

    as_command rcbot.waypoint_givetype <type1> [type2] [type3]

you can give a waypoint multiple types. Use the type names in the table above.

# Removing a waypoint type

    as_command rcbot.waypoint_removetype <type1> [type2] [type3]

you can remove multiple types. Use the type names in the table above.

# Toggling a waypoint type

    as_command rcbot.waypoint_toggletype <type1> [type2] [type3]

you can toggle multiple types. Use the type names in the table above.

# Changing waypoint types

to change all waypoints with a particular type to another use

    as_command rcbot.waypoint_convert_type <type_from> <type_to>
    
for example

    as_command rcbot.waypoint_convert_type end important

# Viewing current waypoint types

Waypoint colour will change depending on waypoint type(s). To view the type(s) on a  waypoint, go to a waypoint and use the command 

    as_command rcbot.waypoint_info

a message will appear on the HUD

# Loading waypoints

Waypoints load automatically at map start up , but sometimes still has issues

    as_command rcbot.waypoint_load
	
The program will try to load the waypoint in the ‘store’ folder first (custom waypoint), and then in the rcw folder if none exists.

# Saving waypoints

    as_command rcbot.waypoint_save

waypoints will be saved in the ‘store’ folder. 

# Clearing waypoints

To start waypoints from scratch use the command

    as_command rcbot.waypoint_clear

# Waypoint considerations

Many waypoints have been converted from RCBot 1, however some waypoint types now differ. 

    1. There should be only one 'end' waypoint at the end of the map
    2. There should be multiple 'important' waypoints to indicate milestone button presses etc.
    3. The 'wait lift' waypoint is now 'wait'
    4. Ladder waypoints aren't used, but bots can still climb ladders without the need for ladder waypoints. Just make sure the path is slightly angled so that bots do not look in the wrong direction going up the ladder.
    

