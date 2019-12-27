# mpv-scripts
This is a collection of my own mpv scripts.

## boss-key.lua

### Requirements:
  - `xdotool` for Linux users

If you press 'b', the screen instantly pauses and minimises. Called like that
because you'd want to hide whatever you're watching when your boss (or mom)
walks in.

Thanks to [@zaza42](https://github.com/zaza42) for his Linux implementation.

## histogram.lua

This script exposes a configurable way to overlay ffmpeg histograms in mpv.  
There is a substantial amount of config available, but this script does *not* support config files, because of the nested options. Please edit the options in the `opts` array in the script itself.  
There are three default keybinds:
 - `h`: Toggle the histogram on/off
 - `H` (`Shift+h`): Cycle between the pixel formats available
 - `Ctrl+h`: Toggle between linear and logarithmic levels

These keybinds can be changed or commented out at the bottom of this file.

![Shamelessly stolen from ffmpeg's wiki](https://trac.ffmpeg.org/raw-attachment/wiki/Histogram/histogram_overlay.jpg)