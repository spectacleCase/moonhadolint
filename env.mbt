///|
fn env_pairs(arguments : String) -> Array[(String, String)] {
  let result : Array[(String, String)] = []
  let parts = tokens(arguments)
  if parts.length() == 0 {
    return result
  }
  if !parts[0].contains("=") {
    let key = parts[0]
    let (_, rest) = first_token(arguments)
    result.push((key, rest.trim().to_owned()))
    return result
  }
  for part in parts {
    match part.split_once("=") {
      None => ()
      Some((key, value)) => result.push((key.to_owned(), value.to_owned()))
    }
  }
  result
}

///|
fn check_env(inst : Instruction, diagnostics : Array[Diagnostic]) -> Unit {
  let pairs = env_pairs(inst.arguments)
  if pairs.length() == 0 {
    diagnostics.push(
      diagnostic(
        "DL3044",
        "warning",
        inst.line,
        "Do not use empty ENV instructions.",
      ),
    )
    return
  }
  for pair in pairs {
    let (key, value) = pair
    if key.is_empty() || value.trim().is_empty() {
      diagnostics.push(
        diagnostic(
          "DL3044",
          "warning",
          inst.line,
          "Do not use environment variables without a value.",
        ),
      )
    }
  }
}
