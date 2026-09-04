///|
fn check_expose(inst : Instruction, diagnostics : Array[Diagnostic]) -> Unit {
  for part in tokens(inst.arguments) {
    if part.has_prefix("$") {
      continue
    }
    let port_text = match part.split_once("/") {
      None => part
      Some((port, _)) => port.to_owned()
    }
    let n = @string.parse_int(port_text) catch {
      _ => {
        diagnostics.push(
          diagnostic(
            "DL3011",
            "error",
            inst.line,
            "Valid UNIX ports range from 0 to 65535.",
          ),
        )
        continue
      }
    }
    if n < 0 || n > 65535 {
      diagnostics.push(
        diagnostic(
          "DL3011",
          "error",
          inst.line,
          "Valid UNIX ports range from 0 to 65535.",
        ),
      )
    }
  }
}

///|
fn check_unique_stage(
  name : String,
  named_stages : Array[String],
  line : Int,
  diagnostics : Array[Diagnostic],
) -> Unit {
  if contains_code(named_stages, name) {
    diagnostics.push(
      diagnostic(
        "DL3024",
        "error",
        line,
        "FROM aliases must be unique. \{name} is used twice.",
      ),
    )
  }
}
