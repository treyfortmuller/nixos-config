{ pkgs, ... }:

# TODO (tff): might want ShellApplication here to avoid
# the implicit i3lock-color dependency here
pkgs.writeShellScriptBin "i3lock-wrap" ''
  i3lock-color --clock                      \
    --no-unlock-indicator                   \
    --color 000000ff                        \
    --wrong-text "nope."                    \
    --time-font "JetBrains Mono:style=Bold" \
    --date-font "JetBrains Mono"            \
    --verif-font "JetBrains Mono"           \
    --wrong-font "JetBrains Mono"           \
    --greeter-font "JetBrains Mono"         \
    --layout-font "JetBrains Mono"          \
    --layout-color ffffffff                 \
    --time-color ffffffff                   \
    --date-color ffffffff                   \
    --verif-color ffffffff                  \
    --wrong-color ffffffff                  \
    --greeter-color ffffffff                \
    --time-size 80                          \
    --date-size 48                          \
    --date-pos "tx-0:ty+75"
''
