; Added in v1.15:
global positionMouse := True ; forces the mouse to be at preset coordinates for the first chest (forces unpauseOnSwitch to be True)
; get the coordinates using Window Spy (right click on autohotkey icon in system tray). Use Screen coordinates
global mousePosX := 670 ; x coordinate of the mouse
global mousePosY := 298 ; y coordinate of the mouse

; Added in v1.12:
global forcePerchDisplay := True ; show text to let the chatters know that it's a forced perch

; Added in v1.10:
global TTS_speed := 3 ; how fast you want your tts dude to speak

; Added in v1.9:
global hotkeyCooldown := 200 ; how many milliseconds the script will wait after getting a hotkey input before registering further inputs (useful for if you accidentally double tap a hotkey so it doesn't break everything)

; As of v1.8:
global unpauseOnSwitch := False ; unpause when switched to instance with ready spawn
global fullscreen := False ; all resets will be windowed, this will automatically fullscreen the instance that's about to be played
global playSound := False ; will play a windows sound or the sound stored as spawnready.mp3 whenever a spawn is ready
global disableTTS := False ; this is the "ready" sound that plays when the macro is ready to go
global fullScreenDelay := 270 ; increase if fullscreening issues
global restartDelay := 200 ; increase if saying missing instanceNumber in .minecraft (and you ran setup)
global maxLoops := 20 ; increase if macro regularly locks
global f3showDuration = 100 ; how many milliseconds f3 is shown for at the start of a run (for verification purposes). Make this -1 if you don't want it to show f3. Remember that one frame at 60 fps is 17 milliseconds, and one frame at 30 fps is 33 milliseconds. You'll probably want to show this for 2 or 3 frames to be safe.
global f3showDelay = 100 ; how many milliseconds of delay before showing f3. If f3 isn't being shown, this is all probably happening during the joining world screen, so increase this number.
global logging = False ; turn this to True to generate logs in macro_logs.txt and DebugView; don't keep this on True because it'll slow things down
global kryptonChecker := True ; change this to False if you want to use Krypton (highly recommend not using Krypton as it will usually break the macro)
global coop := False ; will automatically open to LAN and prepare "/time set 0" (without sending command) when you join a world

; Autoresetter Options:
; The autoresetter will automatically reset if your spawn is greater than a certain number of blocks away from a certain point (ignoring y)
global centerPointX := -217.5 ; this is the x coordinate of that certain point
global centerPointZ := 226.5 ; this is the z coordinate of that certain point
global radius := 25 ; if this is 10 for example, the autoresetter will not reset if you are within 10 blocks of the point specified above. Set this smaller for better spawns but more resets
; if you would only like to reset the blacklisted spawns or don't want automatic resets, then just set this number really large (1000 should be good enough), and if you would only like to play out whitelisted spawns, then just make this number negative
global giveAngle := False ; Give the angle (TTS) that you need to travel at to get to your starting point

; Multi options (single-instance users ignore these)
global instanceFreezing := True ; you probably want to keep this on (true)
global freeMemory := False ; free memory of an instance when it suspends (keep this False unless you're low on RAM since it causes lag and slowness)
global affinity := True ;
global lowBitmaskMultiplier := 0.3 ; for affinity, find a happy medium, max=1.0; lower means more threads to the main instance and less to the background instances, higher means more threads to background instances and less to main instance
global obsDelay := 50 ; increase if not changing scenes in obs
global wallSwitch := True ; switch to an alternate scene (set OBS hotkey to F12) when all instances are resetting