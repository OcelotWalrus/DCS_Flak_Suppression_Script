# Bald Coyote's Flak Suppression Script

It is highly recommended to watch this great video to better understand the concept of Flak Supression : [The Lost Art of Flak Suppression! — Spud Spike](https://www.youtube.com/watch?v=1K7AQ4TPKEk). This script aims to reproduce the same concept Spud Spike has done in the mission editor, only making it a lot easier to implement in your mission, suppressing the need for mission editor to create 3 triggers for EACH AAA/Flak battery in the mission (it gets very tidious). This script also allows for more customization of the behavior of the AAA/Flak Battery.

This is a very lightweight script and does not affect the performance on a mission (it has been tried with 23 different AAA/Flak batteries each containing 8 units and the game was running smoothely).

This script depends on the [mist_4_5_126.lua](https://github.com/mrSkortch/MissionScriptingTools) script.

## What is the logic behind this script ?

How the script works is that if a Flak/AAA Battery's overall health (health % of the whole group) loses a certain amount of %, the AI of that group will be turned OFF, simulating the crew fleeing, not being able to operate the battery due to enemy fire. After a certain amount of time, the battery can be operational again and have is AI turned ON by the script. If that battery's overall health loses a certain % of health again, it will be supressed again etc...

For example if you have a AAA Battery that has 10% set as the "suppression" % step, the battery will be supressed every time it loses 10% of its health, which means it's able to withstand 10 attacks from enemy fire (theoretically).

Besides that, if a AAA Battery's health goes below a certain percentage, the AI will be permanently turned OFF by the script, simulating the crew completely fleeing due to too much of the crew being wounded/killed by enemy fire, or fleeing from overwhelming enemy fire. 

## How do I use this script ?

Implementing this script in your mission is very similar to implementing [Skynet I.A.D.](https://github.com/walder/Skynet-IADS) if this it is familiar to you.

### Step № 1

First, create a simple trigger that triggers unpon mission start. Add a `DO SCRIPT FILE` action and select your own copy of `mist_4_5_126.lua`.

<img width="2560" height="1440" alt="Capture" src="https://github.com/user-attachments/assets/8c438f9b-41b4-4acd-aeb8-3a42167befc2" />

Then, add a second `DO SCRIPT FILE` action and select your own copy of the Flak Suppression Script.

<img width="2560" height="1440" alt="Capture2" src="https://github.com/user-attachments/assets/157ebd3d-9ac9-4098-8b53-fed6f4222f6b" />

### Step № 2

Create a final `DO SCRIPT` action. It is in this script that you will configure the Flak Suppression Script at your will for your own mission. Here is how you do it :

```lua
-- 1. These are parameters to customize the script (in this example the default values are kept)

BaldCoyoteFlakSupressionScript.default_min_offline_time = 90 -- secs. the minimum amount of time a battery has to have its AI OFFLINE when suppressed
BaldCoyoteFlakSupressionScript.default_max_offline_time = 300 -- secs. the maximum amount of time a battery can have its AI OFFLINE when suppressed
BaldCoyoteFlakSupressionScript.default_supression_percentage_step = 25 -- %. step of the total site's health percentage at which its AI will go OFFLINE. basically, AI offline happens every x percentages down from 100
BaldCoyoteFlakSupressionScript.default_min_operating_health = 35 -- %. If the overall flak site group's health goes below, the AI will be turned OFFLINE no matter whether it's been supressed or not
BaldCoyoteFlakSupressionScript.debugging = false -- prints out debug information during the mission inside DCS. When set to FALSE, it will still print out debug information in the dcs.log file
BaldCoyoteFlakSupressionScript.update_time_step = 1 -- secs. How often the main loop is ran. If you have a lot of AAA/Flak Batteries setup, you might wanna increase this variable
BaldCoyoteFlakSupressionScript.debugging_message_stayon_time = 1 -- secs. how long debugging messages should stay on the DCS screen

-- 2. Injecting your AAA/Flak Batteries into the script

-- This is the function that actually injects the batteries into the script
BaldCoyoteFlakSupressionScript:addFlakSite(flak_battery_name, flak_min_offline_time, flak_max_offline_time, flak_offline_percent_step, flak_flee_percentage)
-- <flak_battery_name> string : name of the AAA/Flak Battery group in the Mission Editor
-- <flak_min_offline_time> number (0-∞) : secs. the minimum amount of time a battery has to have its AI OFFLINE when suppressed (optional, if not set will use default value)
-- <flak_max_offline_time> number (0-∞) : secs. the maximum amount of time a battery can have its AI OFFLINE when suppressed (optional, if not set will use default value)
-- <flak_offline_percent_step> number (1-99) : %. step of the total site's health percentage at which its AI will go OFFLINE. basically, AI offline happens every x percentages down from 100
-- <flak_flee_percentage> number (1-99) : %. If the overall flak site group's health goes below, the AI will be turned OFFLINE no matter whether it's been supressed or not
```

And that's it !

## Example of real mission use

Here is an actual setup of the script to give you an idea.

```lua
-- Implementation of my personal Flak Supression System Script
-- All the AAA/Flak sites in this mission have the same parameters.
local flak_min_offline_time = 8*60 -- min. x mins. unoperational before recovery
local flak_max_offline_time = 13*60 -- max. x mins. unoperational before recovery
local flak_offline_percent_step = 25 -- flak site will become unoperational every x% of its health
local flak_flee_percentage = 45 -- if flake site health goes below x%, the whole crew flees at the site is abandoned

BaldCoyoteFlakSupressionScript.debugging = false -- enables/disables debugging message logs of the Flak Supression Script
BaldCoyoteFlakSupressionScript.update_time_step = 5 -- interval between flak supression script updates. This is a big mission so 5 is a good tradeoff.

local flak_sites_names = {
  "100mm AAA Battery #1",
  "100mm AAA Battery #2",
  "100mm AAA Battery #3",
  "100mm AAA Battery #4",
  "100mm AAA Battery #5",
  "57mm AAA Battery #1",
  "57mm AAA Battery #2",
  "57mm AAA Battery #3",
  "Command Center Defense",
  "SA-2 No.1 AAA 100mm DEFENSE",
  "SA-2 No.1 AAA 57mm DEFENSE",
  "SA-2 No.2 AAA 100mm DEFENSE",
  "SA-2 No.2 AAA 57mm DEFENSE",
  "Mobile AAA Site #1",
  "Mobile AAA Site #2",
  "Mobile AAA Site #3",
  "Mobile AAA Site #4",
  "Mobile AAA Site #5",
  "Mobile AAA Site #6",
  "Mobile AAA Site #7",
  "Mobile AAA Site #8"
}

-- Actually plug in the Flak/AAA Sites to the script system
for i=1,#flak_sites_names do
  BaldCoyoteFlakSupressionScript:addFlakSite(flak_sites_names[i], flak_min_offline_time, flak_max_offline_time, flak_offline_percent_step, flak_flee_percentage)
end
```
