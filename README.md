# mpv-scripts
This is intended to become a collection of my own mpv scripts. So far there's
just one.

## boss-key.lua
If you press 'b', the screen instantly pauses and minimises. Called like that
because you'd want to hide whatever you're watching when your boss (or mom)
walks in.

Started out as a gist, and win32 only. Only after a while I noticed 
[@zaza42](https://github.com/zaza42) had forked it and added the Linux
functionality I had looked for. I've taken the opportunity to rework it since
the performance was terrible (taking upwards of a second to minimise after
keypress). I've mostly rewritten it and eliminated the lag. Future possible
features I'm considering are things like darkening the screen so that
taskbar miniatures don't reveal anything either. If you've got ideas shoot them
at the issue tracker.