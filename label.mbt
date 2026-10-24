///|
fn valid_label_key(key : String) -> Bool {
  if key.is_empty() {
    return false
  }
  for ch in key {
    match ch {
      'a'..='z' | '0'..='9' | '.' | '_' | '-' => ()
      _ => return false
    }
  }
  true
}

///|
fn check_label(inst : Instruction, diagnostics : Array[Diagnostic]) -> Unit {
  for pair in env_pairs(inst.arguments) {
    let (key, _) = pair
    if !valid_label_key(key) {
      diagnostics.push(
        diagnostic(
          "DL3048",
          "warning",
          inst.line,
          "Label keys should use lowercase alphanumerics plus dot, underscore, or dash.",
        ),
      )
    }
  }
}

///|
fn check_required_labels(
  seen : Array[String],
  required : Array[String],
  diagnostics : Array[Diagnostic],
) -> Unit {
  for label in required {
    if !contains_code(seen, label) {
      diagnostics.push(
        diagnostic(
          "DL3049",
          "warning",
          1,
          "Configured label \{label} was not found.",
        ),
      )
    }
  }
}
