--[[
  * skiptosilence.lua
  *
  * AUTHOR: detuur
  * License: MIT
  * link: https://github.com/detuur/mpv-scripts
  * 
  * This script skips to the next silence in the file. The
  * intended use for this is to skip until the end of an
  * opening sequence, at which point there's usually for at
  * least a short moment some silence.
  *
  * The default keybind is F3. You can change this by adding
  * the following line to your input.conf:
  *     KEY script-binding skip-to-silence
  * 
  * In order to tweak the script parameters, you can place the
  * text below, between the template markers, in a new file at
  * script-opts/skiptosilence.conf in mpv's user folder. The
  * parameters will be automatically loaded on start.

****************** TEMPLATE FOR skiptosilence.conf ******************
# Maximum amount of noise to trigger, in terms of dB.
# The default is -30 (yes, negative). -60 is very sensitive,
# -10 allows quite a bit of background noise.
quietness = -30

# Minimum duration of silence to trigger
duration = 0.1
************************** END OF TEMPLATE **************************
--]]

local opts = {
    quietness = -30,
    duration = 0.1
}

local mp = require 'mp'
local msg = require 'mp.msg'
local options = require 'mp.options'

old_speed = 1
old_vid_track = "1"

function doSkip()
    setAudioFilter(true)
    setVideoFilter(true, mp.get_property_native("width"), mp.get_property_native("height"))

    mp.observe_property("af-metadata/skiptosilence", "string", foundSilence)

    --old_vid_track = mp.get_property_native("vid")
    --mp.set_property("vid", "no")

    old_speed = mp.get_property_native("speed")
    mp.set_property("speed", 100)
end

function foundSilence(name, value)
    if value == "{}" then
        --mp.log("info", "emptyval detected")
        --mp.set_property("speed", 100)
        return
    end

    mp.set_property("speed", old_speed)

    mp.unobserve_property(foundSilence)

    setAudioFilter(false)
    setVideoFilter(false, 0, 0)

    timecode = string.match(value, "%d+%.?%d+")
    --mp.log("info", value)
    --mp.set_property("vid", old_vid_track)
    --mp.log("info", "seeking to "..timecode)
    mp.command("seek "..timecode.." absolute")

end

function init()
    local af_table = mp.get_property_native("af")
    af_table[#af_table + 1] = {
        enabled=false,
        label="skiptosilence",
        name="lavfi",
        params= {
            graph = "silencedetect=noise=-30dB:d=0.1"
        }
    }
    mp.set_property_native("af", af_table)

    local vf_table = mp.get_property_native("vf")
    vf_table[#vf_table + 1] = {
        enabled=false,
        label="skiptosilence-blackout",
        name="lavfi",
        params= {
            graph = "nullsink,testsrc"
        }
    }
    mp.set_property_native("vf", vf_table)
end

function setAudioFilter(state)
    local af_table = mp.get_property_native("af")
    if #af_table > 0 then
        for i = #af_table, 1, -1 do
            if af_table[i].label == "skiptosilence" then
                af_table[i].enabled = state
                mp.set_property_native("af", af_table)
                return
            end
        end
    end
end

function setVideoFilter(state, width, height)
    local vf_table = mp.get_property_native("vf")
    if #vf_table > 0 then
        for i = #vf_table, 1, -1 do
            if vf_table[i].label == "skiptosilence-blackout" then
                vf_table[i].enabled = state
                vf_table[i].params = {
                    graph = "nullsink,color=c=black:s="..width.."x"..height
                }
                mp.set_property_native("vf", vf_table)
                return
            end
        end
    end
end

options.read_options(opts)
init()

mp.add_key_binding("F3", "skip-to-silence", doSkip)