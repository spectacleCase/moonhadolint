///|
test "structured FROM and COPY nodes" {
  let source =
    #|FROM --platform=linux/amd64 alpine:3.19 AS builder
    #|COPY --from=runtime --chown=user:user src dest/
    #|
  let doc = @moonhadolint.parse_dockerfile(source).unwrap()
  match doc.instructions[0].node {
    From(from) => {
      inspect(from.image, content="alpine")
      assert_true(from.tag is Some("3.19"))
      assert_true(from.platform is Some("linux/amd64"))
      assert_true(from.as_name is Some("builder"))
    }
    _ => fail("expected FROM node")
  }
  match doc.instructions[1].node {
    Copy(copy) => {
      assert_true(copy.from_stage is Some("runtime"))
      inspect(copy.dest, content="dest/")
      inspect(copy.sources[0], content="src")
    }
    _ => fail("expected COPY node")
  }
}

///|
test "JSON CMD is parsed into argv" {
  let doc = @moonhadolint.parse_dockerfile(
    "FROM alpine:3.19\nCMD [\"echo\", \"ok\"]\n",
  ).unwrap()
  match doc.instructions[1].node {
    Cmd(cmd) => {
      assert_true(cmd.form is Json)
      inspect(cmd.argv.length(), content="2")
      inspect(cmd.argv[1], content="ok")
    }
    _ => fail("expected CMD node")
  }
}

///|
test "shell subset flags unquoted expansions and unguarded cd" {
  let result = @moonhadolint.lint_source(
    (
      #|FROM alpine:3.19
      #|RUN echo $HOME && cd /tmp && rm -rf $@
      #|USER nobody
      #|
    ),
  ).unwrap()
  assert_true(result.has_code("SC2086"))
  assert_true(result.has_code("SC2164"))
  assert_true(result.has_code("SC2068"))
  let quoted = @moonhadolint.lint_source(
    (
      #|FROM alpine:3.19
      #|RUN echo "$HOME" && cd /tmp || exit 1
      #|USER nobody
      #|
    ),
  ).unwrap()
  assert_false(quoted.has_code("SC2086"))
  assert_false(quoted.has_code("SC2164"))
}

///|
test "instruction order requires FROM or ARG first" {
  let result = @moonhadolint.lint_source("WORKDIR /app\nFROM alpine:3.19\n").unwrap()
  assert_true(result.has_code("DL3061"))
}
