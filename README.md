# mpv-scripts
This is a collection of my own mpv scripts. Valuable contributions have been made by:  
- [@zaza42](https://github.com/zaza42): Linux implementation of boss-key.lua
- [@microraptor](https://github.com/microraptor): Bug fixes, streamlining,
  and features to skiptosilence.lua and histogram.lua

## boss-key.lua (updated 2022-02-27)
Instantly pauses and minimises the screen at the push of a button (by default
`b`). Called like that because you'd want to hide whatever you're watching when
your boss (or mom) walks in.

The default keybind is `b`. You can change this by adding
the following line to your `input.conf`:
```
KEY script-binding boss-key
```

### Requirements:
  - Linux users: `xdotool`. Wayland is currently unsupported. PRs welcome!

## skiptosilence.lua (updated 2022-02-27)
This script skips to the next silence in the file. The
intended use for this is to skip until the end of an
opening or ending sequence, at which point there's often a short
period of silence.

The default keybind is `F3`. You can change this by adding
the following line to your `input.conf`:
```
KEY script-binding skip-to-silence
```

In order to tweak the script parameters, you can place the
text below in a new file at
`script-opts/skiptosilence.conf` in mpv's user folder. The
parameters will be automatically loaded on start.

```
# Maximum amount of noise to trigger, in terms of dB.
# The default is -30 (yes, negative). -60 is very sensitive,
# -10 is more tolerant to noise.
quietness = -30

# Minimum duration of silence to trigger.
duration = 0.1

# The fast-forwarded audio can sound jarring. Set to 'yes'
# to mute it while skipping.
mutewhileskipping = no
```

## histogram.lua (updated 2022-02-27)
This script exposes a configurable way to overlay ffmpeg histograms in mpv.  
There is a substantial amount of config available, but this script does *not*
support config files, because of the nested options. Please edit the options
in the `opts` array in the script itself.  

There are three default keybinds:
 - `h`: Toggle the histogram on/off
 - `H` (`Shift+h`): Cycle between the pixel formats available
 - `Alt+h`: Toggle between linear and logarithmic levels

These keybinds can be changed by placing the following lines
in your `input.conf`:
```
KEY script-binding toggle-histogram
KEY script-binding cycle-histogram-pixel-format
KEY script-binding cycle-histogram-levels-mode
```
### A note on hardware decoding
The histogram filter is not compatible with hardware decoding. As a result, the
default behaviour is to automatically disable any hardware decoding while the
filter is on. This behaviour can be changed in the aforementioned `opts` array.

### Waveform version
A version of this script adapted by [@MikelSotomonte](https://github.com/MikelSotomonte) for displaying waveforms instead can be found at [his repo](https://github.com/MikelSotomonte/mpv-waveform).

![Shamelessly stolen example from ffmpeg's wiki](https://trac.ffmpeg.org/raw-attachment/wiki/Histogram/histogram_overlay.jpg)
