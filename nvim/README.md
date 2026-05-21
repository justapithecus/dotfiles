# Neovim

LazyVim-based Neovim configuration with local customizations.

## Contents

- `install.sh`: Clones LazyVim starter, applies overlay, and syncs plugins.
- `overlay/`: Local configuration merged on top of the LazyVim starter.
- `pkgs/`: Per-platform package lists (`base-linux.txt`, `base-darwin.txt`, `native-build-linux.txt`, `native-build-darwin.txt`).
- `starter.ref`: Reference branch for the upstream starter repo.

## Install

```sh
./nvim/install.sh --backup --yes
```

Options:
- `--native`: Install native build dependencies (gcc, cmake, rust, etc.).
- `--backup`: Move existing `~/.config/nvim` to a timestamped backup.
- `--overwrite`: Remove existing `~/.config/nvim` before installing.
- `--yes`: Non-interactive mode.

## Overlay structure

```
overlay/
├── init.lua              # Disables unused providers, loads lazy.lua
└── lua/
    ├── config/
    │   ├── lazy.lua      # Lazy.nvim bootstrap and plugin spec paths
    │   └── options.lua   # Editor options
    └── plugins/
        ├── copilot.lua         # Copilot configuration
        ├── disable_mason.lua   # Disables Mason (system LSPs preferred)
        ├── disable_nvim_cmp.lua
        ├── lsp.lua             # LSP keymaps and behavior
        ├── lsp_servers.lua     # Server-specific settings
        └── ...
```

## Notes

- Mason is disabled; LSP servers are expected to be installed via the system package manager.
- Python, Ruby, and Perl providers are disabled in `init.lua`.
