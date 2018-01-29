-- This script minimises and pauses the window when
-- the boss key (default 'b') is pressed.
-- Can be overwriten in input.conf as follows:
-- KEY script-binding boss-key

utils = require 'mp.utils'

function boss_key()
	mp.set_property_native("pause", true)
	minimize_win32()
end

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
