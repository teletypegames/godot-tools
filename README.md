# godot-tools

CI/CD templates for [Godot](https://godotengine.org) (4.x) game
projects, in the same spirit as [ebitengine-tools](../ebitengine-tools)
and [tic80-tools](../tic80-tools).

- `example-makefile.make` — project Makefile: the shared targets
  (`build`, `run`, `check`, `web`, `clean`, see below) plus `export`,
  `watch` and the desktop
  binary targets (`binaries`, `binary-win-x86`, `binary-win-x64`,
  `binary-linux-x64`, `binary-mac-universal`).
- `.woodpecker.yaml` (written by New Game, not kept here) — a one-line
  marker (`platform: godot`): the full pipeline (version → build → upload → publish) is served by the update server's Woodpecker
  configuration extension — preview it with
  `curl "https://teletypegames.org/build/config?platform=godot"`.
- `example-export_presets.cfg` — `export_presets.cfg` with the **Web**
  preset the Makefile exports plus the desktop presets (**Windows
  x86**, **Windows x64**, **Linux x64**, **Mac universal**). Web
  threads are disabled (`variant/thread_support=false`, Godot 4.3+) so
  the build runs without COOP/COEP (cross-origin isolation) headers.
- `example-tasks.json` — VS Code `.vscode/tasks.json`: `build` (the default
  build task, a headless import) and `web` as `warpengine` tasks, `run (Godot)`
  (`make run` with a local `godot`) and `edit (Godot)` (the local editor).
- `hello/` — the smallest Godot project: one scene with a centred
  "Hello World" label (`project.godot`, `hello.tscn`, `.gitignore`),
  Compatibility renderer, ETC2 ASTC import on for the universal mac
  export. The project name is only the window title, so it builds
  under any project name.
- `warp-template.json` — what *WarpEngine: New Game* (WarpEngine
  Toolbox) copies for "Start from the template only": the Makefile,
  the VS Code tasks, the export presets and the `hello/` files at the
  project root. The toolbox sets `PROJECT` and writes
  `.woodpecker.yaml` and `metadata.json` itself.

## Dev container

`warp-template.json` has a `devcontainer` key that the WarpEngine Toolbox reads
(an older toolbox ignores it): a new project gets `.devcontainer/` from
`example-devcontainer.json` and `example-devcontainer.Dockerfile` — the CI
builder image the host names (`{builderImage}`) plus git and a `dev` user —
so a computer with only Docker builds with the same toolchain as the pipeline.
The tasks of `example-devcontainer-tasks.json` are merged into
`.vscode/tasks.json`: `dev image` builds the container image, `play` builds the
game and plays it in the host's web runtime. In the container `dev` reaches the export templates of the image (kept under `/root`) through a link, so `make web` exports `dist/web`, which the `play` task plays in the Play panel. The Godot editor and the game window do not open in the container: `run (Godot)` builds there and runs `make run` here, and `edit (Godot)` opens the local editor.
The container editor gets its extensions from `example-devcontainer.json`: the WarpEngine Toolbox, Makefile Tools (its configure prompts off; the Toolbox tasks build) and the Godot tools; their language server is set to `host.docker.internal`, so the editor in the container talks to the Godot editor running on this computer (Docker Desktop and OrbStack forward it to its loopback port). It also mounts the computer's Docker socket, with the Docker CLI in the image and `dev` in the socket's group, so the Toolbox lists, starts and restarts the local engine's containers from inside the container.
For an existing game repo, *WarpEngine: Add Dev Container* adds it and merges
the tasks, keeping yours.

## Makefile contract

The Makefile has the targets every WarpEngine template shares: `build`, `run`, `check` (the CI's check step runs it in the builder image),
`clean`, `web` (the Web preset's export in `dist/web`, which Play plays). `warp-engine check makefile` of the
[WarpEngine CLI](https://wiki.teletypegames.org/godoc/warp-engine-cli/latest/cmd/warp-engine/)
checks a project against it. `check` is the headless import, which
fails on a broken project.

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
3. Create `.woodpecker.yaml` with the line `platform: godot` (a one-line marker — the
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
  --build-arg GODOT_VERSION=4.7.1 \
  -t git.teletypegames.org/build/godot-builder:4.7.1 .
docker push git.teletypegames.org/build/godot-builder:4.7.1
```

Detailed documentation lives on the wiki: `/development/godot`.
