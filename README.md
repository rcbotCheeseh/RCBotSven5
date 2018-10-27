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
