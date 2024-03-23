ardour {
    ["type"]    = "dsp",
    name        = "Noedig MIDI Activate Tracks",
    category    = "Example", -- "Utility"
    license     = "MIT",
    author      = "Gideon van der Kolf",
    description = [[Activate/deactivate all tracks with names starting with numbers based on received CC or Program Change messages.]]
}

-- Gideon van der Kolf, 2024-03-23
--
-- Place this script in ~/.config/ardour8/scripts
--
-- In Ardour, create a MIDI track and add this script as a plugin on that track.
--
-- This script will activate/deactivate other tracks based on the received CC
-- or Program Change messages. All tracks whose names start with the number 
-- that is the same as the received MIDI message's value will be activated.
-- All other tracks whose names start with a number that doesn't correspond to
-- the value of the received MIDI message will be deactivated.
--
-- Example:
--
--      Track: Ctrl     --> Contains this script. Name does not start with number,
--                          so it will not be affected by this script.
--      Track: 1 Piano
--      Track: 1 Synth
--      Track: 2 Strings
--      Track: 3 Yoshimi
--      Track: 3 Guitar
--      etc.
--
-- When a MIDI message with value 1 is received by this script on the "Ctrl"
-- track, tracks starting with "1" (Piano, Synth) will be activated while all
-- the other number-tracks will be deactivated.
-- When a MIDI message with value 2 is received, track "2 Strings" will be
-- activated and the rest deactivated. And so on.

--------------------------------------------------------------------------------
-- User settings

USE_CC = true
CC_CONTROL_NUMBER = 7
USE_PROGRAM_CHANGE = false

--------------------------------------------------------------------------------

function dsp_ioconfig ()
    return { { midi_in = 1, midi_out = 1, audio_in = 0, audio_out = 0}, }
end

--------------------------------------------------------------------------------

function getRoutePlugins(route)
    local plugins = {}

    local ip = 0
    while true do
        p = route:nth_plugin(ip)
        if p:isnil() then
            break
        end
        if not p:isnil() then
            plugins[#plugins + 1] = p
        end
        ip = ip + 1
    end

    return plugins
end

--------------------------------------------------------------------------------

function activateTracksStartingWithNumber(num)
    
    local routes = Session:get_routes()

    for i,route in ipairs(routes:table()) do

        -- Get patch number from string name
        local n = tonumber( string.sub(route:name(), 1, 1) )
        if n == nil then
            n = -1
        end

        -- Only change activation if track starts with a number >= 1
        if n >= 1 then
            -- Activate track if number matches
            route:set_active(n == num, nil)
        end

    end
    
end

--------------------------------------------------------------------------------

function midiEventData(event)
    return event["data"]
end

function midiEventType(eventData)
    local event_type
    if #eventData == 0 then
        event_type = -1
    else
        event_type = eventData[1] >> 4
    end
    return event_type
end

TYPE_NOTEOFF = 0x8
TYPE_NOTEON = 0x9
TYPE_CC = 0xB
TYPE_PROGRAM = 0xC

function is_noteoff(eventData)
    return (#eventData == 3) and (midiEventType(eventData) == TYPE_NOTEOFF)
end

function is_noteon(eventData)
    return (#eventData == 3) and (midiEventType(eventData) == TYPE_NOTEON)
end

function is_cc(eventData)
    return (#eventData == 3) and (midiEventType(eventData) == TYPE_CC)
end

function is_program(eventData)
    return (#eventData == 2) and (midiEventType(eventData) == TYPE_PROGRAM)
end

--------------------------------------------------------------------------------

function dsp_run (_, _, n_samples)
    assert (type(midiin) == "table")
    assert (type(midiout) == "table")
    local cnt = 1;

    function tx_midi (time, data)
        midiout[cnt] = {}
        midiout[cnt]["time"] = time;
        midiout[cnt]["data"] = data;
        cnt = cnt + 1;
    end

    -- for each incoming midi event
    for _,event in pairs (midiin) do

        local data = midiEventData(event)

        if is_cc(data) then
            
            if USE_CC then
                local cc = data[2]
                local val = data[3]
                
                if cc == CC_CONTROL_NUMBER then
                    activateTracksStartingWithNumber(val)
                end
            end
            
        elseif is_program(data) then
        
            if USE_PROGRAM then
                local val = data[2]
                activateTracksStartingWithNumber(val)
            end
            
        end
    end
end
