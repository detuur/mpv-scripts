--[[
  * histogram.lua v.2020-01-27
  *
  * AUTHOR: detuur
  * License: MIT
  * link: https://github.com/detuur/mpv-scripts
  * 
  * This script exposes a configurable way to overlay ffmpeg
  * histograms in mpv.
  * 
  * There are three default keybinds:
  *     h - Toggle the histogram on/off
  *     H - Cycle between the pixel formats available
  *     Ctrl+h - Toggle between linear and logarithmic levels
  * These keybinds can be changed by placing the following lines
  * in your input.conf:
  *     KEY script-binding toggle-histogram
  *     KEY script-binding cycle-histogram-pixel-format
  *     KEY script-binding cycle-histogram-levels-mode
  *
  * There is a substantial amount of config available, but this
  * script does *not* support config files, because of the nested
  * options. Please edit the options directly in the `opts` array
  * below.
--]]

local opts = {
    -- These options directly control the `histogram` filter in ffmpeg, consult
    -- its options at this link: https://ffmpeg.org/ffmpeg-filters.html#histogram
    hist = {
        level_height = 200,
        scale_height = 12,
        display_mode = "stack", -- Possible options: {"stack", "parade", "overlay"}
        levels_mode = "linear", -- Possible options: {"linear", "logarithmic"}
        components = 7,
        fgopacity = 0.7,
        bgopacity = 0.5
    },

    -- The different pixel formats to switch between allow you to see RGB histograms
    -- for YUV-encoded video and vice-versa, as well as cycle between different bit-
    -- depths. "default" is a passthrough of the video's original pixel format.
    pixel_fmt = "default",
    -- As a rule of thumb, pixel formats with an 'a' allow for transparency and look
    -- prettier, but are also slower, which is why the higher bit-depths have alpha-
    -- less formats. Get a full list of supported and unsupported formats by running
    -- mpv with `mpv --vf=format=fmt=help` on the command line.
    fmts_available = { "default", "gray", "gbrap", "gbrp10", "gbrp12", "yuva444p", "yuva444p10", "yuv444p12" },

    -- These options control the positioning of the histogram. `pos` is only respected
    -- if x and y are nil.
    overlay = {
        pos = "right-upper", -- Possible options: {"right", "left"}"-"{"lower", "upper"}
        margin = 10,
        x = nil,
        y = nil
    }
}

--/!\ DO NOT EDIT BELOW THIS LINE /!\

local mp = require 'mp'
local msg = require 'mp.msg'

local fa_ri = {}    --Reverse index of fmts_available

function buildGraph()
    local o = {}
    for key,value in pairs(opts.hist) do table.insert(o, key.."="..value) end

    local x,y
    if (opts.overlay.x ~= nil and opts.overlay.y ~= nil) then
        x = opts.overlay.x
        y = opts.overlay.y
    elseif opts.overlay.pos == "right-upper" then
        x = "W-w-"..opts.overlay.margin
        y = opts.overlay.margin
    elseif opts.overlay.pos == "left-lower" then
        x = opts.overlay.margin
        y = "H-h-"..opts.overlay.margin
    elseif opts.overlay.pos == "right-lower" then
        x = "W-w-"..opts.overlay.margin
        y = "H-h-"..opts.overlay.margin
    else
        x = opts.overlay.margin
        y = opts.overlay.margin
    end

    return "split=2[a][b],[b]"
           ..(opts.pixel_fmt ~= "default" and "format="..opts.pixel_fmt.."," or "")
           .."histogram="
           ..table.concat(o, ":")
           ..",format=yuva444p[hh],[a][hh]overlay="
           .."x="..x
           ..":y="..y
end

function toggleFilter()
    local vf_table = mp.get_property_native("vf")
    if #vf_table > 0 then
        for i = #vf_table, 1, -1 do
            if vf_table[i].label == "histogram" then
                for j = i, #vf_table-1 do
                    vf_table[j] = vf_table[j+1]
                end
                vf_table[#vf_table] = nil
            else
                vf_table[#vf_table + 1] = {
                    label="histogram",
                    name="lavfi",
                    params= {
                        graph = buildGraph()
                    }
                }
            end
            mp.set_property_native("vf", vf_table)
            return
        end
    end
end

function cycleFmt()
    opts.pixel_fmt = opts.fmts_available[fa_ri[opts.pixel_fmt]%#opts.fmts_available + 1]
    mp.osd_message("Histogram: pixel format set to "..opts.pixel_fmt)
    rebuildGraph()
end

function cycleLevels()
    opts.hist.levels_mode = (opts.hist.levels_mode == "logarithmic" and "linear" or "logarithmic")
    mp.osd_message("Histogram: levels mode set to "..opts.hist.levels_mode)
    rebuildGraph()
end

function rebuildGraph()
    local vf_table = mp.get_property_native("vf")
    if #vf_table > 0 then
        for i = #vf_table, 1, -1 do
            if vf_table[i].label == "histogram" then
                vf_table[i].params.graph = buildGraph()
                mp.set_property_native("vf", vf_table)
                return
            end
        end
    end
end

function init()
    for k,v in pairs(opts.fmts_available) do
        fa_ri[v]=k
    end
end

init()

mp.add_key_binding("h", "toggle-histogram", toggleFilter)
mp.add_key_binding("H", "cycle-histogram-pixel-format", cycleFmt)
mp.add_key_binding("ctrl+h", "cycle-histogram-levels-mode", cycleLevels)
