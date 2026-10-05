do

-----------------------------------------------------------------------
--                           Bald Coyote's                           --
--                     //Flak Supression Script\\                    --
--                                                                   --
--                            Ver. 1.0.0                             --
--                            /09.26.26/                             --
--                                                                   --
--       Dependencies :                                              --
--         -- The latest version of DCS World                        --
--         -- mist_4_5_126.lua                                       --
--                                                                   --
--                                                                   --
--       Usage :                                                     --
--                                                                   --
--       This script simulates realistic Flak/AAA behavior           --
--       by turning a Flak/AAA site's AI off if it gets damage       --
--       up to a certain point. Then, after a given time, the site   --
--       is able to recover and the AI goes back online.             --
--                                                                   --
-----------------------------------------------------------------------

-----------------------------------------------------------------------
--                          Initialization                           --
-----------------------------------------------------------------------

local script_version = "1.0.0"
env.info("--- FLAK SUPRESSION VERSION: "..tostring(script_version))
-- Create the "class" for the script
BaldCoyoteFlakSupressionScript = {}
BaldCoyoteFlakSupressionScript.__index = BaldCoyoteFlakSupressionScript

-----------------------------------------------------------------------
--             Variables used internally by the script               --
-----------------------------------------------------------------------
---
local flak_sites = {}

BaldCoyoteFlakSupressionScript.default_min_offline_time = 90  -- 1 mins. 30 secs.
BaldCoyoteFlakSupressionScript.default_max_offline_time = 300 -- 5 mins.
BaldCoyoteFlakSupressionScript.default_supression_percentage_step = 25 -- %. step of the total site's health percentage it which it will go offline. basically, AI offline happens every x percentages down from 100
BaldCoyoteFlakSupressionScript.default_min_operating_health = 35 -- %. If the overall flak site group's health goes below, the AI will be turned OFF no matter whether it's been supressed or not.
BaldCoyoteFlakSupressionScript.debugging = false
BaldCoyoteFlakSupressionScript.update_time_step = 1 -- secs. How often the main loop is ran.
BaldCoyoteFlakSupressionScript.debugging_message_stayon_time = 1 -- secs. how long debugging messages should stay on

local function print_to_log( message )

  env.info("//FLAK SUPRESSION V"..tostring(script_version).." // "..tostring(message))
  if ( BaldCoyoteFlakSupressionScript.debugging == true ) then
    trigger.action.outText("//FLAK SUPRESSION V"..tostring(script_version).." // "..tostring(message), BaldCoyoteFlakSupressionScript.debugging_message_stayon_time)
  end

end

-----------------------------------------------------------------------
--             Flak Supression Script Main Logic/Loop                --
-----------------------------------------------------------------------

local function update()

  if ( #flak_sites == 0 ) then -- no flak sites defined, no update loop needed
    print_to_log("No Flak Sites defined.")
    return
  end

  for i=1,#flak_sites do

    if ( flak_sites[i].ai_active == true ) then -- AI online

      local flak_me_group = Group.getByName(flak_sites[i].group_name_me)
      if ( flak_me_group == nil or flak_me_group:isExist() == false ) then -- if group isn't found or is destroyed, call it off
        
        print_to_log("Tried to run actions on Flak Site '"..tostring(flak_sites[i].group_name_me).."' but it either doesn't exist or has been destroyed.")
      
      else

        -- Update the overall health of the group
        -- here we calculate the average health
        local total_health_percent = 0
        for key,value in pairs(flak_me_group:getUnits()) do

          local curr_life_percent = value:getLife() / value:getLife0()
          total_health_percent = total_health_percent + curr_life_percent

        end

        local overall_group_health_percent = ( total_health_percent / flak_sites[i].starting_unit_count ) * 100
        flak_sites[i].overall_group_health = overall_group_health_percent
        print_to_log("Updated Flak Site '"..tostring(flak_sites[i].group_name_me).."' health ("..tostring(overall_group_health_percent).."%)")

        -- Determine whether the flak site has been supressed or not. If yes, turn the AI off and start the countdown till reactivation
        if ( ( overall_group_health_percent < flak_sites[i].min_operating_health ) or ( ( flak_sites[i].overall_group_health_at_last_supression - overall_group_health_percent ) > flak_sites[i].supression_percentage_step ) ) then
          print_to_log("Flak Site '"..tostring(flak_sites[i].group_name_me).."' has been determined to be supressed.")

          flak_sites[i].overall_group_health_at_last_supression = overall_group_health_percent
          flak_sites[i].time_before_reactivation = math.random(flak_sites[i].min_offline_time, flak_sites[i].max_offline_time)
          flak_sites[i].time_since_offline = 0
          flak_sites[i].ai_active = false

          flak_me_group:getController():setOnOff(false) -- actually turn the AI OFF
          print_to_log("Turned Flak Site '"..tostring(flak_sites[i].group_name_me).."' OFF.")

        end

    end
    
    else -- AI offline

      flak_sites[i].time_since_offline = flak_sites[i].time_since_offline + BaldCoyoteFlakSupressionScript.update_time_step -- update the timer
      print_to_log("Flak Site '"..tostring(flak_sites[i].group_name_me).."' has "..tostring(flak_sites[i].time_before_reactivation - flak_sites[i].time_since_offline).." secs. left before reactivation.")

      if ( flak_sites[i].time_before_reactivation <= flak_sites[i].time_since_offline ) then -- site can go back online
        flak_sites[i].time_since_offline = 0
        flak_sites[i].ai_active = true

        local flak_me_group = Group.getByName(flak_sites[i].group_name_me)
        if ( flak_me_group == nil or flak_me_group:isExist() == false ) then -- if group isn't found or is destroyed, call it off
        
          print_to_log("Tried to turn back ON Flak Site '"..tostring(flak_sites[i].group_name_me).."' but it either doesn't exist or has been destroyed.")

        else

          flak_me_group:getController():setOnOff(true) -- actually turn the AI ON
          print_to_log("Turned Flak Site '"..tostring(flak_sites[i].group_name_me).."' back ON.")

        end

      end

    end

  end

end

local update_loop = mist.scheduleFunction(update, {}, 1, BaldCoyoteFlakSupressionScript.update_time_step)

-----------------------------------------------------------------------
--             Flak Supression Script export functions               --
-----------------------------------------------------------------------

function BaldCoyoteFlakSupressionScript:addFlakSite( site_group_name, min_offline_time, max_offline_time, supression_percentage_step, min_operating_health )

  local flak_me_group = Group.getByName(site_group_name)

  -- Use default values for optional input variables
  min_offline_time = min_offline_time or BaldCoyoteFlakSupressionScript.default_min_offline_time
  max_offline_time = max_offline_time or BaldCoyoteFlakSupressionScript.default_max_offline_time
  supression_percentage_step = supression_percentage_step or BaldCoyoteFlakSupressionScript.default_supression_percentage_step
  min_operating_health = min_operating_health or BaldCoyoteFlakSupressionScript.default_min_operating_health

  if ( flak_me_group == nil ) then -- if group isn't in the mission file, exit and return an error to the log file
    print_to_log("Tried adding group '"..tostring(site_group_name).."' to script by name, but it wasn't found in the mission.")
    return
  end
  if ( type(min_offline_time) ~= "number" ) then -- min_offline_time must be a number 
    print_to_log("Tried adding group '"..tostring(site_group_name).."' to script by name, but its given min_offline_time parameter isn't a number.")
    return
  end
  if ( type(max_offline_time) ~= "number" ) then -- min_offline_time must be a number 
    print_to_log("Tried adding group '"..tostring(site_group_name).."' to script by name, but its given max_offline_time parameter isn't a number.")
    return
  end
  if ( min_offline_time >= max_offline_time ) then -- min_offline_time must be a number 
    print_to_log("Tried adding group '"..tostring(site_group_name).."' to script by name, but its given min_offline_time parameter is greater or equal to max_offline_time.")
    return
  end
  if ( type(supression_percentage_step) ~= "number" ) then -- min_offline_time must be a number 
    print_to_log("Tried adding group '"..tostring(site_group_name).."' to script by name, but its given supression_percentage_step parameter isn't a number.")
    return
  end
  if ( type(min_operating_health) ~= "number" ) then -- min_offline_time must be a number 
    print_to_log("Tried adding group '"..tostring(site_group_name).."' to script by name, but its given min_operating_health parameter isn't a number.")
    return
  end

  -- Add a new entry to the flak_sites dictionary
  flak_sites[#flak_sites+1] = {
    group_name_me = site_group_name, -- group's name in ME
    ai_active = true, -- that group's AI status
    time_since_offline = 0, -- time in secs. since the AI has gone OFF (Flak site supressed)
    min_offline_time = min_offline_time, -- minimum amount of time the site's AI has to be offline after flak supressed
    max_offline_time = max_offline_time, -- maximum amount of time the site's AI has to be offline after flak supressed
    time_before_reactivation = 0, -- gets redefined with math.random(min_offline_time, max_offline_time) every time the flak gets supressed
    overall_group_health = 100, -- %. health in percentage of the whole group itself.
    overall_group_health_at_last_supression = 100, -- %. health of the group the last time the flak site got supressed
    supression_percentage_step = supression_percentage_step, -- %. step of the total site's health percentage it which it will go offline. basically, AI offline happens every x percentages down from 100
    min_operating_health = min_operating_health, -- %. If the overall flak site group's health goes below, the AI will be turned OFF no matter whether it's been supressed or not.
    starting_unit_count = #flak_me_group:getUnits() -- how many units are originally in the group. This is important because in DCS if a unit is killed it's removed from the dictionary. So you can have the overall group health at 100% even if half the units are dead.
  }

  -- print out to the log the create site's parameters for debug
  print_to_log("Flak Site created.")
  for key,value in pairs(flak_sites[#flak_sites]) do
    print_to_log("Key : '"..tostring(key).."'——— Value : '"..tostring(value).."'")
  end

end

end
