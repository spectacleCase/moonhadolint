///|
test "inline ignore suppresses the next instruction" {
  let source =
    #|# hadolint ignore=DL3006
    #|FROM ubuntu
    #|USER nobody
    #|
  let doc = @moonhadolint.parse_dockerfile(source).unwrap()
  assert_true(doc.instructions[0].ignored_codes.length() == 1)
  let result = @moonhadolint.lint_source(source).unwrap()
  assert_false(result.has_code("DL3006"))
}

///|
test "options and config ignore rules" {
  let source = "FROM ubuntu\nUSER nobody\n"
  let options : @moonhadolint.LintOptions = {
    ignored: ["DL3006"],
    trusted_registries: [],
    required_labels: [],
  }
  let result = @moonhadolint.lint_source_with(source, options).unwrap()
  assert_false(result.has_code("DL3006"))
  let parsed = @moonhadolint.parse_config(
    (
      #|ignored:
      #|  - DL3006
      #|trustedRegistries:
      #|  - docker.io
      #|
    ),
  )
  inspect(parsed.ignored.length(), content="1")
  inspect(parsed.trusted_registries[0], content="docker.io")
}

///|
test "trusted registries emit DL3026" {
  let options : @moonhadolint.LintOptions = {
    ignored: ["DL3006"],
    trusted_registries: ["docker.io"],
    required_labels: [],
  }
  let trusted = @moonhadolint.lint_source_with(
    "FROM ubuntu:22.04\nUSER nobody\n", options,
  ).unwrap()
  assert_false(trusted.has_code("DL3026"))
  let untrusted = @moonhadolint.lint_source_with(
    "FROM ghcr.io/demo/app:1.0\nUSER nobody\n", options,
  ).unwrap()
  assert_true(untrusted.has_code("DL3026"))
}
