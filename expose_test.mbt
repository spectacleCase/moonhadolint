///|
test "invalid EXPOSE ports trigger DL3011" {
  let bad = @moonhadolint.lint_source(
    "FROM alpine:3.19\nEXPOSE 99999\nUSER nobody\n",
  ).unwrap()
  assert_true(bad.has_code("DL3011"))
  let ok = @moonhadolint.lint_source(
    "FROM alpine:3.19\nEXPOSE 80/tcp 443\nUSER nobody\n",
  ).unwrap()
  assert_false(ok.has_code("DL3011"))
}

///|
test "duplicate FROM aliases trigger DL3024" {
  let result = @moonhadolint.lint_source(
    (
      #|FROM alpine:3.19 AS app
      #|FROM alpine:3.19 AS app
      #|USER nobody
      #|
    ),
  ).unwrap()
  assert_true(result.has_code("DL3024"))
}
