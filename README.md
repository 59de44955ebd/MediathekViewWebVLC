# MediathekViewWebVLC

This Lua extension for VLC allows to search for videos in the media libraries of german public TV stations. Additionally, it can also be used to watch the livestreams of those TV stations.

It's based on [MediathekViewWeb](https://mediathekviewweb.de/) and its JSON API. Since VLC's vlc.stream Lua module doesn't support POST request, [Patrick Hein](https://github.com/bagbag) kindly added an additional GET query endpoint to MediathekViewWeb.

**Requirements**

VLC 3.x

**Installation**

To install, place file "mediathekviewweb.lua" in the following directory, depending on your operating system:

a) Install for current user only

Windows: %APPDATA%\vlc\lua\extensions  
Linux: ~/.local/share/vlc/lua/extensions  
macOS: /Users/<your_name>/Library/Application Support/org.videolan.vlc/lua/extensions

b) Install for all users

Windows: %ProgramFiles%\VideoLAN\VLC\lua\extensions  
Linux: /usr/lib/vlc/lua/extensions  
macOS: /Applications/VLC.app/Contents/MacOS/share/lua/extensions

**Screenshots**

* MediathekViewWebVLC Search in VLC 3.0.12/Win 8.1:

  ![](screenshots/vlc01.jpg)

* MediathekViewWebVLC listing Livestreams in VLC 3.0.12/Win 8.1:

  ![](screenshots/vlc02.jpg)
