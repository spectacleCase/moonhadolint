///|
test "invalid and required labels" {
  let invalid = @moonhadolint.lint_source(
    "FROM alpine:3.19\nLABEL Maintainer=demo\nUSER nobody\n",
  ).unwrap()
  assert_true(invalid.has_code("DL3048"))
  let options : @moonhadolint.LintOptions = {
    ignored: [],
    trusted_registries: [],
    required_labels: ["org.opencontainers.image.source"],
  }
  let missing = @moonhadolint.lint_source_with(
    "FROM alpine:3.19\nUSER nobody\n", options,
  ).unwrap()
  assert_true(missing.has_code("DL3049"))
  let present = @moonhadolint.lint_source_with(
    "FROM alpine:3.19\nLABEL org.opencontainers.image.source=https://example.com\nUSER nobody\n",
    options,
  ).unwrap()
  assert_false(present.has_code("DL3048"))
  assert_false(present.has_code("DL3049"))
}
