# Changelog

## 0.1.0

- Scaffolded MoonHadolint as `spectacleCase/moonhadolint`.
- Added a Dockerfile parser for common instructions, comments, and line continuations.
- Added hadolint-style rules for image tags, WORKDIR, USER, apt/apk/pip, ADD/COPY, and pipes.
- Added text and JSON diagnostic reports.
- Added a native CLI: `lint`, `json`, `parse`, `sample`, `bad-sample`, and `rules`.
