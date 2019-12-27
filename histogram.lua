-- AUTHOR: detuur
-- License: MIT
-- link: https://github.com/detuur/mpv-scripts

-- This script exposes a configurable way to overlay ffmpeg histograms in mpv.

-- There is a substantial amount of config available, which should go into
-- $MPV_HOME/lua-settings/histogram.conf. Check out the template conf file in
-- the linked repo.

-- There are three default keybinds:
--  h - Toggle the histogram on/off
--  H - Cycle between the pixel formats available
--  Ctrl+h - Toggle between linear and logarithmic levels
-- These keybinds can be changed or commented out at the bottom of this file.

-- Documentation of options: https://ffmpeg.org/ffmpeg-filters.html#histogram

local mp = require 'mp'
local opt = require 'mp.options'
local msg = require 'mp.msg'

local opts = {
    hist = {
        level_height = nil,
        scale_height = nil,
        display_mode = nil,
        levels_mode = nil,
        components = nil,
        fgopacity = 0.7,
        bgopacity = 0.5
    },
    pixel_fmt = "default",
    fmts_available = { "default", "gray", "gbrap", "gbrp10", "gbrp12", "yuva444p", "yuva444p10", "yuv444p12" },
    overlay = {
        pos = "right-upper",
        margin = 10,
        x = nil,
        y = nil
    }
}

local fa_ri = {}

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
            if vf_table[i].label == "histo" then
                vf_table[i].enabled = not vf_table[i].enabled
                mp.set_property_native("vf", vf_table)
                return
            end
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
            if vf_table[i].label == "histo" then
                vf_table[i].params.graph = buildGraph()
                mp.set_property_native("vf", vf_table)
                return
            end
        end
    end
end

function init()
    opt.read_options(opts, "histogram.conf")

    local vf_table = mp.get_property_native("vf")
    vf_table[#vf_table + 1] = {
        enabled=false,
        label="histo",
        name="lavfi",
        params= {
            graph = buildGraph()
        }
    }
    mp.set_property_native("vf", vf_table)

    for k,v in pairs(opts.fmts_available) do
        fa_ri[v]=k
    end
end

init()
mp.add_key_binding("h", "toggle-histogram", toggleFilter)
mp.add_key_binding("H", "cycle-histogram-pixel-format", cycleFmt)
mp.add_key_binding("l", "cycle-histogram-levels-mode", cycleLevels)