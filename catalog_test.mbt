///|
test "rule catalog stays in sync with report" {
  let rules = @moonhadolint.all_rules()
  inspect(rules.length(), content="45")
  assert_true(@moonhadolint.has_rule("DL3006"))
  assert_true(@moonhadolint.has_rule("DL3049"))
  assert_true(@moonhadolint.has_rule("DL4006"))
  assert_true(@moonhadolint.has_rule("SC2086"))
  let text = @moonhadolint.report_rules()
  assert_true(text.contains("DL3022"))
  assert_true(text.contains("45"))
}
