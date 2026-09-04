///|
test "empty ENV values trigger DL3044" {
  let empty_value = @moonhadolint.lint_source(
    "FROM alpine:3.19\nENV FOO=\nUSER nobody\n",
  ).unwrap()
  assert_true(empty_value.has_code("DL3044"))
  let space_form = @moonhadolint.lint_source(
    "FROM alpine:3.19\nENV FOO\nUSER nobody\n",
  ).unwrap()
  assert_true(space_form.has_code("DL3044"))
  let ok = @moonhadolint.lint_source(
    "FROM alpine:3.19\nENV FOO=bar BAZ=1\nUSER nobody\n",
  ).unwrap()
  assert_false(ok.has_code("DL3044"))
}
