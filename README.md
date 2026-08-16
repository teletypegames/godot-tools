# godot-tools

CI/CD templates for [Godot](https://godotengine.org) (4.x) game
projects, in the same spirit as [ebitengine-tools](../ebitengine-tools)
and [tic80-tools](../tic80-tools).

- `example-makefile.make` — project Makefile: local dev targets
  (`build`, `run`, `web`, `export`, `watch`, `clean`), the desktop
  binary targets (`binaries`, `binary-win-x86`, `binary-win-x64`,
  `binary-linux-x64`, `binary-mac-universal`).
- `example-woodpecker.yaml` — a one-line marker (`platform: godot`): the
  full pipeline (version → build → upload → publish) is served by the update server's Woodpecker
  configuration extension — preview it with
  `curl "https://teletypegames.org/build/config?platform=godot"`.
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
3. Copy `example-woodpecker.yaml` to `.woodpecker.yaml` (a one-line marker — the
   pipeline itself is served by the update server; add `name:` when the
   software name differs from the repo name) and add the
   `application_token` secret in Woodpecker (an ApplicationToken with
   the `update` + `upload` scopes, created in the admin).
   The `godot-builder` image tag (and with it the export-template
   version) is set server-side in the update server's `ci_platforms`
   config, not per repo.
4. Copy `example-tasks.json` to `.vscode/tasks.json`.

The served pipeline uploads `$(PROJECT)-$(VERSION).html.zip` and the desktop
binary zips (`$(PROJECT)-$(VERSION)-<target>.zip`, targets: `win-x86`,
`win-x64`, `linux-x64`, `mac-universal`) via `/build/upload`, then triggers
`/build/publish?platform=godot&name=$(PROJECT)&version=$(VERSION)`, which
attaches them to the release as ReleaseAssets. Godot cross-exports all
desktop platforms from the linux CI image with the official export
templates; mac is a single universal (intel + arm) build with Godot's
built-in ad-hoc codesign — per-arch mac export would need custom-built
templates.

## Builder image

`builder.Dockerfile` wraps `barichello/godot-ci` (editor + web export
templates) with make/zip preinstalled as
`git.teletypegames.org/build/godot-builder`, so the build step no longer
runs `apt-get` on every run. The tag tracks the Godot version:

```sh
docker build --platform linux/amd64 -f builder.Dockerfile \
  --build-arg GODOT_VERSION=4.6 \
  -t git.teletypegames.org/build/godot-builder:4.6 .
docker push git.teletypegames.org/build/godot-builder:4.6
```

Detailed documentation lives on the wiki: `/development/godot`.
