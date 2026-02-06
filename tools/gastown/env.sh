# gastown environment
# Ensures the gt binary (installed via go install) is on PATH.
# No side effects beyond PATH. Safe to source multiple times.

if [ -d "$HOME/go/bin" ]; then
  case ":$PATH:" in
    *":$HOME/go/bin:"*) ;;
    *) export PATH="$HOME/go/bin:$PATH" ;;
  esac
fi
