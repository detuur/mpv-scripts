-- AUTHORS: detuur, zaza42
-- License: MIT
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
	    mp.command([[run cmd /c echo m > \\.\pipe\mpv-boss-key-]]..utils.getpid())
	elseif platform == 'linux' then
	    utils.subprocess({ args = {'xdotool', 'getactivewindow', 'windowminimize'} })
	end
end

-- Windows is a princess (a very ugly one at that) and needs an external process
-- to minimize mpv, with which we communicate through named pipes. I spent an
-- entire day shouting at my screen to arrive at the code below. This went
-- through several complete rewrites as every iteration broke in subtly
-- different ways. Did you know that Powershell and CMD's echo commands behave
-- slightly differently, one refusing to properly write to some streams where
-- the other doesn't? Did you know Powershell's Events and any kind of async
-- is absolute DOG SHIT which will happily chooch in an interactive session only
-- to shit in your face when put inside a script? Honestly I could write several
-- kb about the bullshit I've encountered but it's past midnight and I just want
-- to watch my weeb shit. Fuck you microsoft.
if platform == 'windows' then
    utils.subprocess_detached({
      args = {'powershell', '-NoProfile', '-Command', [[&{
$bosspid = ]]..utils.getpid()..[[

# Construct the named pipe's name
$pipename = -join('mpv-boss-key-',$bosspid)
$fullpipename = -join("\\.\pipe\", $pipename)

# This will run in a separate thread
$minimizeloop = {
    param($pipename, $bosspid)
    # Create the named pipe
    $pipe = new-object System.IO.Pipes.NamedPipeServerStream($pipename)

    # Compile the Win32 API function call
    $signature='[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
    $showWindowAsync = Add-Type -memberDefinition $signature -name "Win32ShowWindowAsync" -namespace Win32Functions -passThru

    # The core loop
    while($true) {
        $pipe.WaitForConnection()
        if ($pipe.ReadByte() -ne 109) {
            break 
        }
        $pipe.Disconnect()
        $showWindowAsync::ShowWindowAsync((Get-Process -id $bosspid).MainWindowHandle, 2)
    }
    $pipe.Dispose()
}

# Exiting this monstrosity (THANKS POWERSHELL FOR BROKEN ASYNC) is surprisingly
# cumbersome. It took literal hours to find something that didn't spontaneously
# combust. Fuck windows.
$bossproc = Get-Process -pid $bosspid -ErrorAction SilentlyContinue
$exitsequence = {
    &{echo q > $fullpipename} 2> $null
    [Environment]::Exit(0)
}
if ((-Not $bossproc) -or $bossproc.HasExited) { $exitsequence.Invoke() }

# Begin watching for events until boss closes
Start-Job -ScriptBlock $minimizeloop -Name "mpvminloop" -ArgumentList $pipename,$bosspid
while($true) {
    Start-Sleep 1
    if ($bossproc.HasExited) { $exitsequence.Invoke() }
}
}]]}})
end

mp.add_key_binding('b', 'boss-key', boss_key)
