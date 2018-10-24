# RCBotSven5
New Angelscript RCBot for Svencoop 5 test

Bots currently walks around and shoot...
waypoints for osprey and sc_another

WIP!!!

# Editor

Visual Studio Code: https://code.visualstudio.com/

# Usage

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
