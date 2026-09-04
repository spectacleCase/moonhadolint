# Changelog

## 0.1.2

- Parse structured instruction nodes for FROM, COPY, ENV, CMD, and RUN.
- Add a small shell checker for SC2086, SC2046, SC2068, and SC2164.
- Add DL3061 for invalid first instructions.

## 0.1.1

- Publish a structured rule catalog used by `rules` output and docs.

- Track multi-stage `FROM` aliases and `COPY --from`.
- Add DL3022 and DL3023 for unknown or self-referencing stages.
- Honor `# hadolint ignore=` comments, `--ignore`, and a small config file.
- Add DL3026 for trusted registries.
- Add DL3003, DL3016, DL3021, DL4003, and DL4004.
- Add GitHub Actions annotation output.
- Add DL3044 for empty ENV values.
- Add DL3011 for invalid EXPOSE ports and DL3024 for duplicate FROM aliases.
- Add apt/yum/dnf/gem, wget/curl, and FROM --platform rules.
- Parse Dockerfile heredoc bodies such as `RUN cat <<EOF`.
- Attach the current FROM stage name to each diagnostic and JSON report.
- Read Dockerfiles from stdin and honor `--threshold error|warning|never`.
- Add DL3048 / DL3049 for invalid and required LABEL keys.
- Publish a structured 40-rule catalog used by `rules` output and docs.

## 0.1.0

- Scaffolded MoonHadolint as `spectacleCase/moonhadolint`.
- Added a Dockerfile parser for common instructions, comments, and line continuations.
- Added hadolint-style rules for image tags, WORKDIR, USER, apt/apk/pip, ADD/COPY, and pipes.
- Added text and JSON diagnostic reports.
- Added a native CLI: `lint`, `json`, `parse`, `sample`, `bad-sample`, and `rules`.
