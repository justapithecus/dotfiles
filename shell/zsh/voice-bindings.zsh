# voice-bindings.zsh — ZLE widgets for voice-to-text input
#
# Ctrl-B  → start recording (arecord in background)
# Ctrl-Y  → stop recording, transcribe, paste into prompt

voice-record-widget() {
  zle -I
  voice-record start 2>&1
  zle reset-prompt
}

voice-stop-paste-widget() {
  zle -I
  voice-record stop 2>/dev/null

  local transcript_file="${VOICE_TRANSCRIPT:-$HOME/.config/voice/state/last.txt}"
  if [[ -f "$transcript_file" ]]; then
    local text
    text="$(<"$transcript_file")"
    if [[ -n "$text" ]]; then
      LBUFFER+="$text"
    fi
  fi

  zle reset-prompt
}

zle -N voice-record-widget
zle -N voice-stop-paste-widget

for map in emacs viins; do
  bindkey -M "$map" '^B' voice-record-widget
  bindkey -M "$map" '^Y' voice-stop-paste-widget
done
