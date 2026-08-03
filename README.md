# godot-tools

CI/CD templates for [Godot](https://godotengine.org) (4.x) game
projects, in the same spirit as [ebitengine-tools](../ebitengine-tools)
and [tic80-tools](../tic80-tools).

- `example-makefile.make` — project Makefile: local dev targets
  (`build`, `run`, `web`, `export`, `watch`, `clean`), the desktop
  binary targets (`binaries`, `binary-win-x86`, `binary-win-x64`,
  `binary-linux-x64`, `binary-mac-universal`) plus the Woodpecker
  pipeline targets (`ci-version`, `ci-export`, `ci-binaries`,
  `ci-upload`, `ci-update`).
- `example-woodpecker.yaml` — Woodpecker pipeline: version → build
  (headless web export + desktop binaries in the `barichello/godot-ci`
  image) → upload (scp to the droparea) → update (calls the
  teletypegames `/update` endpoint with `platform=godot`).
- `example-export_presets.cfg` — `export_presets.cfg` with the **Web**
  preset the Makefile exports plus the desktop presets (**Windows
  x86**, **Windows x64**, **Linux x64**, **Mac universal**). Web
  threads are disabled (`variant/thread_support=false`, Godot 4.3+) so
  the build runs without COOP/COEP (cross-origin isolation) headers.
- `example-tasks.json` — VS Code `.vscode/tasks.json` with the common
  dev tasks: **Run** (`godot --path .`, default build task,
  `Cmd+Shift+B`), **Edit**, **Export Web** and **Make build**.

## Usage in a game repo

1. Copy `example-makefile.make` to `Makefile` and set `PROJECT`
   (the web build is packaged as `$(PROJECT)-$(VERSION).html.zip`).
2. Copy `example-export_presets.cfg` to `export_presets.cfg` (or merge
   the presets into your existing file). Keep the preset names in sync
   with the Makefile (`EXPORT_PRESET` for web, the `B_PRESET` values of
   the `binary-*` targets for desktop), and set
   `application/bundle_identifier` in the Mac preset to your project.
   For the universal mac export enable ETC2 ASTC texture import in
   `project.godot`:

   ```ini
   [rendering]

   textures/vram_compression/import_etc2_astc=true
   ```
3. Copy `example-woodpecker.yaml` to `.woodpecker.yaml` and add the
   `droparea_ssh_password` / `update_secret_key` secrets in Woodpecker.
   Match the `godot-builder` image tag to the Godot version the
   project is made with (e.g. `4.6`) — the underlying
   `barichello/godot-ci` image ships the matching export templates.
4. Copy `example-tasks.json` to `.vscode/tasks.json`.

The pipeline uploads `$(PROJECT)-$(VERSION).html.zip` and the desktop
binary zips (`$(PROJECT)-$(VERSION)-<target>.zip`, targets: `win-x86`,
`win-x64`, `linux-x64`, `mac-universal`) to the droparea, then triggers
`/update?platform=godot&name=$(PROJECT)&version=$(VERSION)`, which
attaches them to the release as ReleaseAssets. Godot cross-exports all
desktop platforms from the linux CI image with the official export
templates; mac is a single universal (intel + arm) build with Godot's
built-in ad-hoc codesign — per-arch mac export would need custom-built
templates.

## Builder image

`builder.Dockerfile` wraps `barichello/godot-ci` (editor + web export
templates) with make/zip preinstalled as
`git.teletypegames.org/internal/godot-builder`, so the build step no longer
runs `apt-get` on every run. The tag tracks the Godot version:

```sh
docker build --platform linux/amd64 -f builder.Dockerfile \
  --build-arg GODOT_VERSION=4.6 \
  -t git.teletypegames.org/internal/godot-builder:4.6 .
docker push git.teletypegames.org/internal/godot-builder:4.6
```

Detailed documentation lives on the wiki: `/development/godot`.
