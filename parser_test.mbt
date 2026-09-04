///|
test "parse sample dockerfile" {
  let doc = @moonhadolint.parse_dockerfile(@moonhadolint.sample_dockerfile()).unwrap()
  inspect(doc.instructions.length(), content="6")
  assert_true(doc.instructions[0].kind is From)
  inspect(doc.instructions[0].arguments, content="alpine:3.19")
  assert_true(doc.instructions[1].kind is Workdir)
  assert_true(doc.instructions[5].form is Json)
}

///|
test "parse joins line continuations" {
  let source =
    #|FROM alpine:3.19
    #|RUN apk add --no-cache \
    #|    curl=8.5.0-r0 \
    #|    git=2.43.0-r0
    #|USER nobody
    #|
  let doc = @moonhadolint.parse_dockerfile(source).unwrap()
  inspect(doc.instructions.length(), content="3")
  inspect(doc.instructions[1].line, content="2")
  assert_true(doc.instructions[1].arguments.contains("curl=8.5.0-r0"))
  assert_true(doc.instructions[1].arguments.contains("git=2.43.0-r0"))
}

///|
test "parse skips comments and blank lines" {
  let source =
    #|# syntax=docker/dockerfile:1
    #|
    #|FROM python:3.12-slim
    #|# install deps
    #|WORKDIR /opt/app
    #|
  let doc = @moonhadolint.parse_dockerfile(source).unwrap()
  inspect(doc.instructions.length(), content="2")
  inspect(doc.instructions[0].line, content="3")
  inspect(doc.instructions[1].line, content="5")
}

///|
test "parse from platform and alias" {
  let source = "FROM --platform=linux/amd64 python:3.12-slim AS base\n"
  let doc = @moonhadolint.parse_dockerfile(source).unwrap()
  inspect(
    doc.instructions[0].arguments,
    content="--platform=linux/amd64 python:3.12-slim AS base",
  )
}

///|
test "parse heredoc RUN body" {
  let source =
    #|FROM alpine:3.19
    #|RUN cat <<EOF
    #|hello
    #|world
    #|EOF
    #|USER nobody
    #|
  let doc = @moonhadolint.parse_dockerfile(source).unwrap()
  inspect(doc.instructions.length(), content="3")
  assert_true(doc.instructions[1].arguments.contains("hello"))
  assert_true(doc.instructions[1].arguments.contains("world"))
  assert_true(doc.instructions[2].kind is User)
}

///|
test "parse empty source" {
  let doc = @moonhadolint.parse_dockerfile("").unwrap()
  inspect(doc.instructions.length(), content="0")
}

///|
test "parse multi-stage and COPY --from" {
  let source =
    #|FROM alpine:3.19 AS builder
    #|WORKDIR /src
    #|COPY . /src
    #|FROM alpine:3.19 AS runtime
    #|COPY --from=builder /src/app /app
    #|
  let doc = @moonhadolint.parse_dockerfile(source).unwrap()
  assert_true(doc.instructions[0].stage is Some("builder"))
  assert_true(doc.instructions[2].stage is Some("builder"))
  assert_true(doc.instructions[3].stage is Some("runtime"))
  assert_true(doc.instructions[4].copy_from is Some("builder"))
}
