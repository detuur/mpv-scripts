--[[
  * skiptosilence.lua v.2023-08-15
  *
  * AUTHORS: detuur, microraptor, Eisa01
  * License: MIT
  * link: https://github.com/detuur/mpv-scripts
  * 
  * This script skips to the next silence in the file. The
  * intended use for this is to skip until the end of an
  * opening sequence, at which point there's often a short
  * period of silence.
  *
  * The default keybind is F3. You can change this by adding
  * the following line to your input.conf:
  *     KEY script-binding skip-to-silence
  * 
  * In order to tweak the script parameters, you can place the
  * text below, between the template markers, in a new file at
  * script-opts/skiptosilence.conf in mpv's user folder. The
  * parameters will be automatically loaded on start.
  *
  * Dev note about the used filters:
  * - `silencedetect` is an audio filter that listens for silence and
  * emits text output with details whenever silence is detected.
  * Filter documentation: https://ffmpeg.org/ffmpeg-filters.html
****************** TEMPLATE FOR skiptosilence.conf ******************
# Maximum amount of noise to trigger, in terms of dB.
# The default is -30 (yes, negative). -60 is very sensitive,
# -10 is more tolerant to noise.
quietness=-30

# Minimum duration of the silence that will be detected to trigger skipping.
silence_duration=0.1
************************** END OF TEMPLATE **************************
--]]

local opts = {
	quietness = -30,
	silence_duration = 0.1,
}

(require 'mp.options').read_options(opts)
local mp = require 'mp'
local msg = require 'mp.msg'

old_speed = 1
was_paused = false
saved_sid = nil
saved_vid = nil
skip_flag = false
initial_skip_time = 0

function doSkip()
	if skip_flag then return end
	-- Get initial time
	initial_skip_time = mp.get_property_native("time-pos")
	if math.floor(initial_skip_time) == math.floor(mp.get_property_native('duration')) then return end
	
	-- Get video dimensions
	local width = mp.get_property_native("width");
	local height = mp.get_property_native("height")
	mp.set_property_native("geometry", ("%dx%d"):format(width, height))
	
	-- Create filters
	mp.command(
		"no-osd af add @skiptosilence:lavfi=[silencedetect=noise=" ..
		opts.quietness .. "dB:d=" .. opts.silence_duration .. "]"
	)

	-- Triggers whenever the `silencedetect` filter emits output
	mp.observe_property("af-metadata/skiptosilence", "string", foundSilence)

	saved_vid = mp.get_property("vid")
	mp.set_property("vid", "no")
	saved_sid = mp.get_property("sid")
	mp.set_property("sid", "no")
	was_paused = mp.get_property_native("pause")
	mp.set_property_bool("pause", false)
	old_speed = mp.get_property_native("speed")
	mp.set_property("speed", 100)
	skip_flag = true
end

function foundSilence(name, value)
	if value == "{}" or value == nil then
		return -- For some reason these are sometimes emitted. Ignore.
	end

	if timecode == nil or timecode < initial_skip_time + 1 then
		return -- Ignore anything less than a second ahead.
	end
	
	mp.set_property("vid", saved_vid)
	mp.set_property("sid", saved_sid)
	mp.set_property_bool("pause", was_paused)
	mp.set_property("speed", old_speed)
	mp.unobserve_property(foundSilence)

	-- Remove used filters
	mp.command("no-osd af remove @skiptosilence")

	-- Seeking to the exact moment even though we've already
	-- fast forwarded here allows the video decoder to skip
	-- the missed video. This prevents massive A-V lag.
	mp.set_property_number("time-pos", timecode)

	-- If we don't wait at least 50ms before messaging the user, we
	-- end up displaying an old value for time-pos.
	mp.add_timeout(0.05, skippedMessage)
	skip_flag = false
end

mp.observe_property('pause', 'bool', function(name, value)
	if value and skip_flag then
		mp.set_property("vid", saved_vid)
		mp.set_property("sid", saved_sid)
		mp.set_property("speed", old_speed)
		mp.unobserve_property(foundSilence)
		mp.command("no-osd af remove @skiptosilence")
		mp.set_property_number("time-pos", initial_skip_time)
		mp.set_property_bool("pause", true)
		skip_flag = false
	end
end)


mp.add_hook('on_unload', 9, function()
	if skip_flag then
		mp.set_property("vid", saved_vid)
		mp.set_property("sid", saved_sid)
		mp.set_property("speed", old_speed)
		mp.unobserve_property(foundSilence)
		mp.command("no-osd af remove @skiptosilence")
		mp.set_property_number("time-pos", mp.get_property_number("time-pos"))
		mp.set_property_bool("pause", was_paused)
		skip_flag = false
	end
end)

function skippedMessage()
	msg.info("Skipped to silence at " .. mp.get_property_osd("time-pos"))
	mp.osd_message("Skipped to silence at " .. mp.get_property_osd("time-pos"))
end

mp.add_key_binding("F3", "skip-to-silence", doSkip)
