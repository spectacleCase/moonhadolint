///|
fn is_ident_start(ch : Char) -> Bool {
  match ch {
    'A'..='Z' | 'a'..='z' | '_' => true
    _ => false
  }
}

///|
fn is_dollar_name(ch : Char) -> Bool {
  if is_ident_start(ch) {
    true
  } else {
    match ch {
      '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' => true
      _ => false
    }
  }
}

///|
fn check_shell(
  inst : Instruction,
  script : String,
  diagnostics : Array[Diagnostic],
) -> Unit {
  let mut quote = ' '
  let mut i = 0
  let mut unquoted_dollar = false
  let mut unquoted_subst = false
  let mut unquoted_at = false
  while i < script.length() {
    match script.get_char(i) {
      None => break
      Some('\\') => i += 2
      Some('\'') => {
        if quote != '"' {
          quote = if quote == '\'' { ' ' } else { '\'' }
        }
        i += 1
      }
      Some('"') => {
        if quote != '\'' {
          quote = if quote == '"' { ' ' } else { '"' }
        }
        i += 1
      }
      Some('`') => {
        if quote == ' ' {
          unquoted_subst = true
        }
        i += 1
      }
      Some('$') =>
        if quote == '\'' {
          i += 1
        } else {
          match script.get_char(i + 1) {
            Some('@' | '*') => {
              if quote == ' ' {
                unquoted_at = true
              }
              i += 2
            }
            Some('(') => {
              if quote == ' ' {
                unquoted_subst = true
              }
              i += 2
            }
            Some('{') => {
              if quote == ' ' {
                unquoted_dollar = true
              }
              i += 2
            }
            Some(ch) =>
              if is_dollar_name(ch) {
                if quote == ' ' {
                  unquoted_dollar = true
                }
                i += 2
              } else {
                i += 1
              }
            None => i += 1
          }
        }
      Some(_) => i += 1
    }
  }
  if unquoted_dollar {
    diagnostics.push(
      diagnostic(
        "SC2086",
        "warning",
        inst.line,
        "Quote variable expansions that should stay as one argument.",
      ),
    )
  }
  if unquoted_subst {
    diagnostics.push(
      diagnostic(
        "SC2046",
        "warning",
        inst.line,
        "Quote command substitution results when they should not be split.",
      ),
    )
  }
  if unquoted_at {
    diagnostics.push(
      diagnostic(
        "SC2068",
        "warning",
        inst.line,
        "Quote $@ or $* expansions to preserve argument boundaries.",
      ),
    )
  }
  if contains_token(script, "cd") && !script.contains("||") {
    diagnostics.push(
      diagnostic(
        "SC2164",
        "warning",
        inst.line,
        "Handle cd failures explicitly before running later commands.",
      ),
    )
  }
}
