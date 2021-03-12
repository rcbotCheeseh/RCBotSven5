=================================================================================
RCbot-AS Hotfix Waypoints by madmax2 for the Svencoop v5.xx 
=================================================================================
Credits to Cheeseh for createing RCbot

http://rcbot.bots-united.com/forums/index.php

-------------------------------------------------

For builds  Aug. 19, 2020 (fe057f1)(don't use this build), Aug. 20, 2020 (ba9c657), and newer 
Not needed for builds Aug. 14, 2020 (ac76796) or older

This rcwa pack is mainly to correct a problem with these specific waypoints that will show up in the latest builds of RCbot_AS (angelscript). I originally used crouchjump waypoints in these rcwa's (& rcw's), in places where they worked better than regular jump wpts, on maps that don't have a long jump module. The latest RCbot_AS builds now require the long jump module for bots to use crouchjump waypoints, So that change broke some of these waypoints, that are included with the current RCbot_AS. 

Basicly, bots will be able to move forward through these maps again if you are using the latest builds. I've converted all the crouchjump wpts to regular jump wpts on these maps:


desertcircle
last
last3
murks
sc_doc
sc_persia
sc_psyko - think I did some minor tweaks at end of slime area (pain flags removed?) and perhaps lava?
sc_royals3

sc_royals2 - only changes the crouchjump at the cavern to a jump, bots won't make these jumps much, player should open the shortcut door

shattered - only changes the crouchjump at upper fans to a jump, bots won't be able to do this until it's fixed

suspension - the rcwa in the git doesn't have crouchjump wpts, but newer bots have big problems on the ladders with that rcwa. It never was updated to my latest rcwa. But my latest rcwa doe's have crouchjump wpts, so this one is now the latest with regular jump wpts

richard_boderman.rcwa:
I also am including richard_boderman, It didn't have any crouchjump wpts, but did have a couple minor issues with the newer builds, probably going back to the beginning of 2020. The main fix was so bots could get up and off that long ladder against the wall, they just could not do it anymore. It's not as good as the older builds, but they can do it when not under attack. They have to crouch & hop up, to get off at the top. Also, bots were no longer launching the helecopter, had to move the button important wpt over to the side away from the HMG. They were confusing it with the HMG box, so would not press it. Finally, bots were no longer entering the room with richard boderman, I had to remove the openslater flag from behind the 2nd door, and adjusted the paths there a bit...

Note: I think all of these rcwa's are the same size as the older rcwa's. The only way to tell if the waypoints are the same or different, is to compare them with a CRC check.
