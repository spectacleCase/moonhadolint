///|
priv struct LogicalLine {
  text : String
  line : Int
}

///|
fn strip_quotes(value : String) -> String {
  if value.length() >= 2 &&
    (
      (value.has_prefix("'") && value.has_suffix("'")) ||
      (value.has_prefix("\"") && value.has_suffix("\""))
    ) {
    value[1:value.length() - 1].to_owned()
  } else {
    value
  }
}

///|
fn heredoc_delimiter(line : String) -> String? {
  match line.find("<<") {
    None => None
    Some(index) => {
      let mut rest = line[index + 2:].to_owned()
      if rest.has_prefix("-") {
        rest = rest[1:].to_owned()
      }
      let (token, _) = first_token(rest)
      let delim = strip_quotes(token)
      if delim.is_empty() || delim.has_prefix("<") {
        None
      } else {
        Some(delim)
      }
    }
  }
}

///|
fn join_continuations(source : String) -> Array[LogicalLine] {
  let physical = split_physical_lines(source)
  let result : Array[LogicalLine] = []
  let mut i = 0
  while i < physical.length() {
    let start_line = i + 1
    let buf = StringBuilder()
    let mut continuing = true
    while continuing && i < physical.length() {
      let raw = physical[i]
      let trimmed = raw.trim_end().to_owned()
      let is_comment = trimmed.trim().has_prefix("#")
      if !is_comment && trimmed.has_suffix("\\") {
        buf.write_string(trimmed[:trimmed.length() - 1].to_owned())
        buf.write_char(' ')
        i += 1
      } else {
        buf.write_string(raw)
        i += 1
        match heredoc_delimiter(trimmed) {
          None => ()
          Some(delim) =>
            while i < physical.length() {
              buf.write_char('\n')
              buf.write_string(physical[i])
              let closed = physical[i].trim().to_owned() == delim
              i += 1
              if closed {
                break
              }
            }
        }
        continuing = false
      }
    }
    result.push({ text: buf.to_string(), line: start_line })
  }
  result
}

///|
pub fn parse_dockerfile(source : String) -> Result[Dockerfile, ParseError] {
  let instructions : Array[Instruction] = []
  let mut current_stage : String? = None
  let mut pending_ignores : Array[String] = []
  for logical in join_continuations(source) {
    let text = logical.text.trim().to_owned()
    if text.is_empty() {
      continue
    }
    if text.has_prefix("#") {
      match parse_ignore_comment(text) {
        None => ()
        Some(codes) =>
          for code in codes {
            pending_ignores.push(code)
          }
      }
      continue
    }
    let (name, rest) = first_token(text)
    if name.is_empty() {
      return Err({ line: logical.line, message: "missing instruction" })
    }
    let kind = kind_of(name)
    let arguments = rest.trim().to_owned()
    if kind is From {
      current_stage = parse_from_stage(arguments)
    }
    let copy_from = if kind is Copy || kind is Add {
      flag_value(arguments, "from")
    } else {
      None
    }
    let ignored_codes = pending_ignores
    pending_ignores = []
    let form = form_of(rest)
    instructions.push({
      kind,
      name,
      arguments,
      line: logical.line,
      form,
      stage: current_stage,
      copy_from,
      ignored_codes,
      node: parse_node(kind, arguments, form),
    })
  }
  Ok({ instructions, })
}

///|
pub fn lint_source(source : String) -> Result[LintResult, ParseError] {
  lint_source_with(source, default_options())
}

///|
pub fn lint_source_with(
  source : String,
  options : LintOptions,
) -> Result[LintResult, ParseError] {
  match parse_dockerfile(source) {
    Err(error) => Err(error)
    Ok(doc) => Ok(lint_dockerfile_with(doc, options))
  }
}
