=================================================================================
RCbot-AS New (WIP) Waypoints by madmax2 for the SvenCoop v5.xx map uplink
=================================================================================
Release 2
===========

Credits to Cheeseh for createing RCbot

http://rcbot.bots-united.com/forums/index.php

Map: uplink.bsp

Map Author:  Map By: Valve Software , Rebuilt By: Soctom

Map Download: Included with SvenCoop 5.xx

The uplink.rcwa is for the Angelscript version of RCbot

Get RCbot-As from https://github.com/rcbotCheeseh/RCBotSven5

Get new & updated waypoints from http://rcbot.bots-united.com/forums/index.php?showforum=37

Recommended number of bots/players: 2 to 3 (3 bots maximum, for single player)

-----------------------------------------------------------------------
-----------------------
Details/Notes/problems
-----------------------

A new rcwa pack, bots can reach the end of map with player help. I don't have them doing everything. These rcwa's are not script ready, they work without a script... I've included 3 waypoints depending on what you prefer. Bots still backtrack but do move forward towards goals better than first release. There have been several fixes for stuck or hung-up bots, some that could be frustrating, like the last 2 vents in the map. Bots still are not waypointed to activate the transmitter dish, players have to do it. See the forums for more details.

uplink.rcwa (default, uplink_endmap4)(19,984 bytes) - Bots can still ride the cargo container over the first gate without player help, though they may be a bit slower doing it. There is an exploit in the map the bots can use to open the 1st gate. After a player activates the transmiter and turns off the steam valve, bots can finish the map, but they will likely need help opening the broken security door when returning to the elevator (bots likely won't open it, it needs to be scripted to make it better). Bots can end the map without getting stuck in vents and blocking players. They have been slowed down in the end area, so players can get in front, if they want to...

uplink_noend3.rcwa (19,976 bytes) - Same rcwa as the default, except bots will not end the map, or trigger the Garg sequence, or enter the last 2 vents.

uplink_end_nocargo2 (19,976 bytes) - Bots won't ride the cargo/container/crane or even climb ladder to get health, path to the ladder is open. A player must ride the container the 1st time, to open the gate. After that, bots can open the gate using the exploit here (after 1st time, the gate button can be pressed through the wall). Bots won't keep looping up to the platform, so forward progress might be faster with this rcwa? It Has all the same fixes as the default rcwa, including the fixed vents at the end of map. bots will trigger ending sequences and end the map, when they get to final area. Just like the default, bots have been slowed down in final areas, if the player wants to be out in front.

Have Fun,
madmax2

