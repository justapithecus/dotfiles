KEYTIMEOUT=1

autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

for map in emacs viins; do
  bindkey -M "$map" '^[b' backward-word
  bindkey -M "$map" '^[f' forward-word

  bindkey -M "$map" $'\e[1;3D' backward-word
  bindkey -M "$map" $'\e[1;5D' backward-word
  bindkey -M "$map" $'\e[1;9D' backward-word
  bindkey -M "$map" $'\e\e[D'   backward-word
  bindkey -M "$map" $'\e[3D'    backward-word
  bindkey -M "$map" $'\e[5D'    backward-word
  bindkey -M "$map" $'\eOD'     backward-word
  bindkey -M "$map" $'\e[1;3C' forward-word
  bindkey -M "$map" $'\e[1;5C' forward-word
  bindkey -M "$map" $'\e[1;9C' forward-word
  bindkey -M "$map" $'\e\e[C'   forward-word
  bindkey -M "$map" $'\e[3C'    forward-word
  bindkey -M "$map" $'\e[5C'    forward-word
  bindkey -M "$map" $'\eOC'     forward-word
done
