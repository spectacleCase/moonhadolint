# Changelog

## Unreleased

- Track multi-stage `FROM` aliases and `COPY --from`.
- Add DL3022 and DL3023 for unknown or self-referencing stages.
- Honor `# hadolint ignore=` comments, `--ignore`, and a small config file.
- Add DL3026 for trusted registries.
- Add DL3003, DL3016, DL3021, DL4003, and DL4004.
- Add GitHub Actions annotation output.

## 0.1.0

- Scaffolded MoonHadolint as `spectacleCase/moonhadolint`.
- Added a Dockerfile parser for common instructions, comments, and line continuations.
- Added hadolint-style rules for image tags, WORKDIR, USER, apt/apk/pip, ADD/COPY, and pipes.
- Added text and JSON diagnostic reports.
- Added a native CLI: `lint`, `json`, `parse`, `sample`, `bad-sample`, and `rules`.
