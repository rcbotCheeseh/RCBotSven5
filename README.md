# RCBot Angelscript for Svencoop 5

Bots currently walk around provided waypoints exist and shoot using most weapons 

Waypoints can be imported from RCBot1 using the converter here:
http://rcbot.bots-united.com/forums/index.php?act=Attach&type=post&id=561

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

# Say commands

say any of the following messages for bots to follow commands

    '<bot name> press [this/that/a] button' - bot will move to your location and press nearest button
    '<bot name> wait [here/there/etc...]' - bot will move to your location and wait for 90 sec
    '<bot name> come [here/there/etc...'] - bot will move to your location but not wait
    '<bot name> pickup [a/some] <ammo/weapon/health/armor>' - bot will move to your location and attempt to pickup what you wanted
    '<bot name> use [this tank]' - bot will use the nearest tank
    '<bot name> follow [me/<player name>]' - bot will follow you or player with <playername>
    '<bot name> heal [me/<player name>]' - bot will heal you or player with <playername>
    '<bot name> revive [me/<player name>]' - bot will revive you or player with <playername>

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
    "team"												unimplemented
    "teamspecific"											Unimplemented
    "crouch"		Put where bot needs to crouch (auto)						OK
    "ladder"		Bots look at waypoint								OK
    "lift"		Coming soon									Unimplemented
    "door"		Coming soon									Unimplemented
    "health"		Put at health pick up or health charger						Fully implemented
    "armor"		Put at battery pickup or HEV charger						Fully implemented
    "ammo"		Put at ammo pickup								OK (partially implemented)
    "checkground"	Bots don't progress until waypoint has a ground (e.g. drawbridge)		OK
    "important"		Put at objective point such as button 
			or breakable needed to move to next stage					OK
    "barney"		Coming soon									Unimplemented
    "defend"		Coming soon									Unimplemented
    "aiming"		Coming soon									Unimplemented
    "crouchjump"	Bots should do a longjump (TO CHANGE NAME)					Bots just do a normal jump atm
    "wait"		Bots wait 1 sec before moving to next waypoint					OK (waitlift unimplemented)
    "pain"		Put at a place where bots will be killed 
			until a trigger_hurt stops working						OK
    "jump"		Put where a bot needs to jump							OK
    "weapon"		Put at a weapon pickup								OK (partially implemented)
    "teleport"		Put at a teleport								OK
    "tank"		Put at a useable turret								Unimplemented
    "grapple"		Bots aim a grapple gun at the waypoint to progress				OK
    "staynear"		Bots tay closer and slow down at waypoint					OK
    "end"		Put at the end of level (main objective)					OK
    "openslater"	Put behind an area that opens later and 
					has path between a wall/door					OK
    "humantower"	Bots crouch and wait for players to jump on them then stand. 
    			Otherwise will jump on crouching players.					OK
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
    
# Debugging

To debug a bot use the command

    as_command rcbot.debug_bot <partial botname>

And make sure to toggle either of the following

    as_command rcbot.debug nav          (debug navigation)
    as_command rcbot.debug think        (debug general)
    as_command rcbot.debug task         (debug tasks)
    as_command rcbot.debug util         (debug utility)
    as_command rcbot.debug visibles     (debug visibles -- not done yet)

Also make sure

    developer 1
    
