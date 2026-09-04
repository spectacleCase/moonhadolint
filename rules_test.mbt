///|
test "sample dockerfile has no issues" {
  let result = @moonhadolint.lint_source(@moonhadolint.sample_dockerfile()).unwrap()
  inspect(result.instruction_count, content="6")
  inspect(result.diagnostics.length(), content="0")
}

///|
test "bad sample hits core hadolint rules" {
  let result = @moonhadolint.lint_source(@moonhadolint.sample_bad_dockerfile()).unwrap()
  assert_true(result.has_code("DL3006"))
  assert_true(result.has_code("DL4000"))
  assert_true(result.has_code("DL3000"))
  assert_true(result.has_code("DL3020"))
  assert_true(result.has_code("DL3004"))
  assert_true(result.has_code("DL3059"))
  assert_true(result.has_code("DL3014"))
  assert_true(result.has_code("DL3025"))
  assert_true(result.has_code("DL3002"))
  assert_true(result.has_errors())
}

///|
test "from latest is a warning" {
  let result = @moonhadolint.lint_source("FROM alpine:latest\nUSER nobody\n").unwrap()
  assert_true(result.has_code("DL3007"))
  assert_false(result.has_code("DL3006"))
}

///|
test "from digest and scratch are exempt" {
  let digest = @moonhadolint.lint_source(
    "FROM alpine@sha256:0123456789abcdef\nUSER nobody\n",
  ).unwrap()
  assert_false(digest.has_code("DL3006"))
  assert_false(digest.has_code("DL3007"))
  let scratch = @moonhadolint.lint_source("FROM scratch\nCOPY app /app\n").unwrap()
  assert_false(scratch.has_code("DL3006"))
}

///|
test "registry port is not treated as a tag" {
  let result = @moonhadolint.lint_source(
    "FROM localhost:5000/demo\nUSER nobody\n",
  ).unwrap()
  assert_true(result.has_code("DL3006"))
}

///|
test "apt and apk pin rules" {
  let apt = @moonhadolint.lint_source(
    (
      #|FROM ubuntu:22.04
      #|RUN apt-get update && apt-get install -y --no-install-recommends curl=7.81.0-1 && rm -rf /var/lib/apt/lists/*
      #|USER nobody
      #|
    ),
  ).unwrap()
  assert_false(apt.has_code("DL3008"))
  assert_false(apt.has_code("DL3009"))
  assert_false(apt.has_code("DL3014"))
  assert_false(apt.has_code("DL3015"))
  let apk = @moonhadolint.lint_source(
    (
      #|FROM alpine:3.19
      #|RUN apk add curl
      #|USER nobody
      #|
    ),
  ).unwrap()
  assert_true(apk.has_code("DL3018"))
  assert_true(apk.has_code("DL3019"))
}

///|
test "pipefail and pip cache" {
  let piped = @moonhadolint.lint_source(
    (
      #|FROM alpine:3.19
      #|RUN wget -O - https://example.com | tar -xz
      #|USER nobody
      #|
    ),
  ).unwrap()
  assert_true(piped.has_code("DL4006"))
  let ok = @moonhadolint.lint_source(
    (
      #|FROM alpine:3.19
      #|SHELL ["/bin/ash", "-o", "pipefail", "-c"]
      #|RUN wget -O - https://example.com | tar -xz
      #|USER nobody
      #|
    ),
  ).unwrap()
  assert_false(ok.has_code("DL4006"))
  let pip = @moonhadolint.lint_source(
    (
      #|FROM python:3.12-slim
      #|RUN pip install requests
      #|USER nobody
      #|
    ),
  ).unwrap()
  assert_true(pip.has_code("DL3013"))
  assert_true(pip.has_code("DL3042"))
}

///|
test "copy from unknown and self stages" {
  let unknown = @moonhadolint.lint_source(
    (
      #|FROM alpine:3.19 AS runtime
      #|COPY --from=builder /app /app
      #|USER nobody
      #|
    ),
  ).unwrap()
  assert_true(unknown.has_code("DL3022"))
  let self_ref = @moonhadolint.lint_source(
    (
      #|FROM alpine:3.19 AS builder
      #|COPY --from=builder /app /app
      #|USER nobody
      #|
    ),
  ).unwrap()
  assert_true(self_ref.has_code("DL3023"))
  let ok = @moonhadolint.lint_source(
    (
      #|FROM alpine:3.19 AS builder
      #|WORKDIR /src
      #|FROM alpine:3.19
      #|COPY --from=builder /src /app
      #|USER nobody
      #|
    ),
  ).unwrap()
  assert_false(ok.has_code("DL3022"))
  assert_false(ok.has_code("DL3023"))
}

///|
test "extra high-frequency rules" {
  let result = @moonhadolint.lint_source(
    (
      #|FROM alpine:3.19
      #|COPY a b dest
      #|RUN cd /tmp && npm install express
      #|CMD echo one
      #|CMD echo two
      #|ENTRYPOINT echo a
      #|ENTRYPOINT echo b
      #|
    ),
  ).unwrap()
  assert_true(result.has_code("DL3021"))
  assert_true(result.has_code("DL3003"))
  assert_true(result.has_code("DL3016"))
  assert_true(result.has_code("DL4003"))
  assert_true(result.has_code("DL4004"))
  assert_true(result.has_code("DL3025"))
}

///|
test "diagnostics record the current FROM stage" {
  let result = @moonhadolint.lint_source(
    (
      #|FROM alpine:3.19 AS builder
      #|WORKDIR src
      #|
    ),
  ).unwrap()
  let mut found = false
  for item in result.diagnostics {
    if item.code == "DL3000" && item.stage is Some("builder") {
      found = true
    }
  }
  assert_true(found)
}

///|
test "failure threshold treats warnings and errors differently" {
  let warnings_only = @moonhadolint.lint_source(
    "FROM alpine:latest\nUSER nobody\n",
  ).unwrap()
  assert_false(warnings_only.has_errors())
  assert_true(warnings_only.should_fail("warning"))
  assert_false(warnings_only.should_fail("error"))
  assert_false(warnings_only.should_fail("never"))
  let errors = @moonhadolint.lint_source("FROM ubuntu\n").unwrap()
  assert_true(errors.should_fail("error"))
  assert_false(errors.should_fail("never"))
}

///|
test "github annotations include file and line" {
  let result = @moonhadolint.lint_source("FROM ubuntu\n").unwrap()
  let text = @moonhadolint.report_github(result, path="Dockerfile")
  assert_true(text.contains("::error file=Dockerfile,line=1::DL3006"))
}

///|
test "json reports keep diagnostic codes" {
  let result = @moonhadolint.lint_source("FROM ubuntu\n").unwrap()
  let text = @moonhadolint.report_text(result)
  assert_true(text.contains("DL3006"))
  let json = @moonhadolint.report_json(result)
  assert_true(json.contains("\"code\": \"DL3006\""))
  assert_true(json.contains("\"ok\": false"))
}
