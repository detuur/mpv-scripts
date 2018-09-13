-- AUTHORS: detuur, zaza42
-- link: https://github.com/detuur/mpv-scripts

-- This script minimises and pauses the window when
-- the boss key (default 'b') is pressed.
-- Can be overwriten in input.conf as follows:
-- KEY script-binding boss-key
-- xdotool is required on Xorg(Linux)

local platform = nil --set to 'linux', 'windows' or 'macos' to override automatic assign
if not platform then
  local o = {}
  if mp.get_property_native('options/vo-mmcss-profile', o) ~= o then
    platform = 'windows'
  elseif mp.get_property_native('options/input-app-events', o) ~= o then
    platform = 'macos'
  else
    platform = 'linux'
  end
end

utils = require 'mp.utils'

-- TODO: macOS implementation?
function boss_key()
	mp.set_property_native("pause", true)
	if platform == 'windows' then
	    minimize_win32()
	elseif platform == 'linux' then
	    utils.subprocess({ args = {'xdotool', 'getactivewindow', 'windowminimize'} })
	end
end

-- This function is still mind-boggingly slow. It's because we need to compile
-- the function call to the win32 API every time we run it. This takes about
-- a second.
-- TODO: cut down on this downtime
function minimize_win32()
	local res = utils.subprocess({
		args = {'powershell', '-NoProfile', '-Command', [[& {
            # Get mpv's PID
            $bosspid = (gwmi win32_process | ? processid -eq $pid).parentprocessid

            # Set function signature
            $signature='[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'

            # Call Add-Type to compile code 
            $showWindowAsync = Add-Type -memberDefinition $signature -name "Win32ShowWindowAsync" -namespace Win32Functions -passThru 

            # Minimize mpv 
            $showWindowAsync::ShowWindowAsync((Get-Process -id $bosspid).MainWindowHandle, 2)
        }]]},
		cancellable = false,
	})
end

mp.add_key_binding('b', 'boss-key', boss_key)