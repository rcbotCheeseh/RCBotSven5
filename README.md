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
    
# cheats

sometimes you need cheats during debugging to make things easier, some are below

    as_command rcbot.godmode
    as_command rcbot.noclip
    as_command rcbot.notarget
    as_command rcbot.notouch                       (puts player into observer mode, ensure survival mode is disabled)
    as_command rcbot.explo [magnitude]             (creates an explosion to kill of bosses quickly)
    as_command rcbot.teleport_wpt [waypoint id]    (teleports player to waypoint ID)
    
# automatically adding bots

edit the config.ini file in BotManager/config

change quota=0 to quota=[number of bots to add automatically]
	
# Bot cam

There is a bot camera that the listen player can sit back and watch, which follows bots in third person. 

switch on botcam

    as_command rcbot.botcam on

switch off botcam

    as_command rcbot.botcam off
    
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

# Objective Scripting
a new addition to RCBOT AS edition is objective scripting for "important" waypoints.  These are waypoints bots will use to complete objectives. The point of using a script is to let bots know to no longer go to completed objectives, and know the order of objectives particularly for complex maps. An additional script for each map is optional which allows bots to understand which objectives to complete.

Objective scripts are .ini files and exist in the waypoint folder. The store folder is checked first.

the hplanet.ini has been done as an example

Each line in the ini file indicates one objective (i.e. one important waypoint) (lines starting '#' are comments). 

    [important waypoint ID],[previous important waypoint ID],[important entity index],[important entity index parameter],[operator], [value]
	
1. [important waypoint ID] is the ID of the important (objective) waypoint. Use rcbot.waypoint_info to get the ID.	
2. [previous important waypoint ID] is the ID of the previous important waypoint that the bot needs to complete before this one. IF none, set this to -1. Usually the first objective will not have a previous objective.	
3. [important entity index] is the entity index of an entity to check against. use rcbot.search <distance> to list the entity index and parameters    
4. [important entity index parameter] can be any of the following (use rcbot.search to get these values)
   - x            (x origin)
   - y            (y origin)
   - z            (z origin)
   - distance     (distance from waypoint in units)
   - frame        (frame for used buttons is typically 1)
   - visible      (1 is visible, 0 is invisible [e.g. for func_wall_toggle])	
5. [operator] can be either
   - \>    (greater than)
   - <    (less than)
   - =     (equal to)      
6. [value] can be any number 
	
The objective is considered completed if the [important entity index parameter] [operator] [value] is true
e.g.
	....,frame, =, 1
	
	will be true if a button is typically pressed and entity index is a button

hplanet is the following:

    #WID, prev, entity search, parameter, operator, value 
    71,    -1,    204, distance,        >,  280
    91,    -1,    205, frame,        =,  1
    129,    71,   238,  frame,        =,  1 
    164,   129,  336,  frame,        =,  1
    176,   164,   325, null, null, null
    180,   176,   391, frame, =, 1
    196,   180,   400, frame, =, 1
    193,   196,   423, distance, >, 180
    
 The first two objectives don't have pre-requisite objectives. The lines with "frame,=,1" are buttons that when pressed will be considered complete.
 The line "176,   164,   325, null, null, null" means that entity index 325 will be null if completed (e.g. its a func_breakable and when its broken the entity is removed)
 
 Tips:
 
 1. check vertical opening doors have been opened by checking previous and after z origin 
 2. check horizontally opened doors by checking previous and after x/y origin
 3. check buttons have been pressed by checking frame == 1
 

