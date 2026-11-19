[Appearance]
ColorScheme=HighContrastDark
Font=DMMono Nerd Font,16,-1,5,50,0,0,0,0,0

[General]
Name=Dev
Parent=FALLBACK/
Icon=utilities-terminal

# Launch + start dir
Command=/bin/zsh
Directory=/home/andrew/workspace
StartInCurrentSessionDir=false

# Tab titles (local vs ssh)
LocalTabTitleFormat=%d  (%n@%H)
RemoteTabTitleFormat=SSH: %u@%h  —  %d

# Good defaults
Environment=TERM=xterm-256color

[Scrolling]
HistoryMode=2
HistorySize=200000
ScrollBarPosition=1

[Terminal Features]
BlinkingCursorEnabled=true

