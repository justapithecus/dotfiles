# gastown environment
# Ensures gt (~/go/bin) and bd (~/.local/bin) are on PATH.
# No side effects beyond PATH. Safe to source multiple times.

for _gt_dir in "$HOME/go/bin" "$HOME/.local/bin"; do
  if [ -d "$_gt_dir" ]; then
    case ":$PATH:" in
      *":$_gt_dir:"*) ;;
      *) export PATH="$_gt_dir:$PATH" ;;
    esac
  fi
done
unset _gt_dir
