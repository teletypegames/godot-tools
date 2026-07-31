# godot-tools

CI/CD templates for [Godot](https://godotengine.org) (4.x) game
projects, in the same spirit as [ebitengine-tools](../ebitengine-tools)
and [tic80-tools](../tic80-tools).

- `example-makefile.make` — project Makefile: local dev targets
  (`build`, `run`, `web`, `export`, `watch`, `clean`) plus the
  Woodpecker pipeline targets (`ci-version`, `ci-export`, `ci-upload`,
  `ci-update`).
- `example-woodpecker.yaml` — Woodpecker pipeline: version → build
  (headless web export in the `barichello/godot-ci` image) → upload
  (scp to the droparea) → update (calls the teletypegames `/update`
  endpoint with `platform=godot`).
- `example-export_presets.cfg` — minimal `export_presets.cfg` with the
  **Web** preset the Makefile exports. Threads are disabled
  (`variant/thread_support=false`, Godot 4.3+) so the build runs
  without COOP/COEP (cross-origin isolation) headers.
- `example-tasks.json` — VS Code `.vscode/tasks.json` with the common
  dev tasks: **Run** (`godot --path .`, default build task,
  `Cmd+Shift+B`), **Edit**, **Export Web** and **Make build**.

## Usage in a game repo

1. Copy `example-makefile.make` to `Makefile` and set `PROJECT`
   (the web build is packaged as `$(PROJECT)-$(VERSION).html.zip`).
2. Copy `example-export_presets.cfg` to `export_presets.cfg` (or merge
   the `Web` preset into your existing presets). Keep the preset name
   in sync with `EXPORT_PRESET` in the Makefile.
3. Copy `example-woodpecker.yaml` to `.woodpecker.yaml` and add the
   `droparea_ssh_password` / `update_secret_key` secrets in Woodpecker.
   Match the `barichello/godot-ci` image tag to the Godot version the
   project is made with (e.g. `4.6`) — the image ships the matching
   export templates.
4. Copy `example-tasks.json` to `.vscode/tasks.json`.

The pipeline uploads `$(PROJECT)-$(VERSION).html.zip` to the droparea,
then triggers
`/update?platform=godot&name=$(PROJECT)&version=$(VERSION)`.

Detailed documentation lives on the wiki: `/development/godot`.
