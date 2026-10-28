# Neovim Configuration

> Personal Neovim setup for modern development. Powered by [lazy.nvim](https://github.com/folke/lazy.nvim) and a curated set of plugins for productivity, LSP, code navigation, formatting, and more.

---

## Features

- Fast startup and lazy loading
- Language Server Protocol (LSP) support
- Fuzzy finding, file explorer, and Git integration
- Code formatting and linting
- AI/code assistant plugins (optional)
- Custom keymaps and commands

---

## Getting Started

1. **Clone this repo** into your Neovim config directory:
   ```sh
   git clone <this-repo-url> ~/.config/nvim
   ```
2. **Open Neovim** and plugins will install automatically.
3. **Review and adapt** settings and plugins to your needs.

---

## Optional MirrorOS highlights

After each colorscheme load, Neovim optionally applies the reviewed highlights from
`/usr/share/mirroros/themes/default/neovim.lua`. Tokyo Night remains the selected scheme; `CursorLineNr`
and FZF are not changed by this integration. If the file is missing, nothing happens. An untrusted path,
invalid file or execution error produces a warning without preventing editor startup. Every path component
must be root-owned, not group- or world-writable, and not a symbolic link; the file is read from the verified
open descriptor. This protects against ordinary-user changes, not concurrent privileged modifications.

The isolated integration test requires no plugins:

```sh
nvim --headless -u NONE -i NONE -n -l tests/mirroros-theme.test.lua
```

## Explicit editor-tool preparation

This candidate requires Neovim 0.12 or later. Treesitter and textobjects use their
`main` APIs; the host's migration from 0.11 is a separate operation.

Tool installation is opt-in, never triggered by opening Neovim or pulling this
repository. Existing hosts can continue using their system, npm, Go and
project-local tools without running preparation.

For a provisioned workstation, restore the locked plugins first, then run as the
editor user with Node/npm and Go explicitly available on PATH:

```sh
nvim --headless '+Lazy! restore' +qa
nvim --headless -c "lua require('config.prepare_tools').run()" -c qa
nvim --headless -c "lua require('config.treesitter').run()" -c qa
```

With MirrorOS's selected NVM runtime, prepend
`$HOME/.nvm/versions/node/v24.22.0/bin` to PATH for both commands. Loading NVM is
not required. System prerequisites are Neovim, Git, curl, unzip, tar, gzip and Go;
Mason package builds may also require the workstation's compiler toolchain.

`lua/config/prepare_tools.lua` owns the desired tools and provider choices.
Preparation installs missing Mason tools, preserves installed versions, checks
receipts and executables, and does not update satisfied tools. Missing tools use
one registry refresh and one package-definition lookup per invocation. It does
not enable additional LSP servers. JSON LSP stays in the user's npm runtime via
`vscode-langservers-extracted@4.10.0`, installed with `--ignore-scripts`; an
existing different version fails for manual review. npm does not lock all
transitive dependencies. Never run preparation as root or use a system-owned npm
prefix. Conform continues preferring project-local Prettier over its PATH fallback.

Failures exit nonzero. Inspect the named package and `:MasonLog` before retrying;
successfully completed tools are preserved on retry. There is a 15-minute bound
per external command, registry refresh or Mason installation. A timed-out Mason
installation is cancelled; no force-install, uninstall or automatic repair is
performed. Keep the runtime PATH unchanged between preparation and editor use.
Publication of workstation-specific changes is a separate reviewed operation.

`lua/config/treesitter.lua` owns the parser list. Its explicit preparation installs
missing parsers and synchronizes existing ones to the selected plugin's manifest,
with at most two concurrent jobs. It checks task results, revision receipts,
loadability and highlight queries. Parser preparation additionally requires
`tree-sitter-cli` >= 0.26.1 from the system package manager and a C compiler. Each
install/update phase has a 15-minute bound and cancels its task on timeout. The
plugin manifest owns required parser/query dependencies; no startup installation
or automatic updates are enabled.

Normal-mode `v` still starts Visual mode. Visual-mode `v` expands using Neovim's
native parent-node selection; `Ctrl+V` contracts using its child-selection
history. Scope selection and the former `<leader>v` initialization mapping were
removed by maintainer agreement. No incremental-selection plugin is needed.
Existing textobject selection, movement and parameter-swap keys are retained.

The isolated contract tests do not install tools or contact registries:

```sh
nvim --headless -u NONE -l tests/lazy-bootstrap.test.lua
nvim --headless -u NONE -l tests/prepare-tools.test.lua
nvim --headless -u NONE -l tests/treesitter-preparation.test.lua
```

Lazy bootstrap clones and checks out its locked revision in a unique sibling
staging directory before publishing the completed installation. Failed staging
directories are retained for diagnosis and are not reused on retry. Remove only
the reported staging directory manually when it is no longer needed. Existing
installations are preserved; an incomplete destination from an older bootstrap
requires manual inspection rather than automatic replacement.

After provisioning, run the normal-configuration integration checks in a separate
headless process. They use temporary buffers, never write fixtures to user files,
and do not authenticate services or install tools:

```sh
nvim --headless -c 'luafile tests/treesitter.test.lua' -c qa
```

These checks validate parser precedence/queries and representative selection,
textobject, Markdown-injection and Emmet behavior. They do not replace attended
GUI checks or prove every plugin/account-dependent workflow is ready.

## Notes

- For plugin details, see `lua/plugins/`.
- For custom settings, see `lua/config/`.
- Contributions and issues are welcome for personal reference.

---

_This configuration is personal and may change at any time._
