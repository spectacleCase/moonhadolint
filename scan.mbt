///|
fn is_ws(ch : Char) -> Bool {
  match ch {
    ' ' | '\n' | '\r' | '\t' => true
    _ => false
  }
}

///|
fn char_at(source : String, pos : Int) -> Char? {
  source.get_char(pos)
}

///|
fn skip_ws(source : String, pos : Int) -> Int {
  let mut i = pos
  while i < source.length() {
    match char_at(source, i) {
      Some(ch) => if is_ws(ch) { i += 1 } else { return i }
      None => return i
    }
  }
  i
}

///|
fn first_token(source : String) -> (String, String) {
  let start = skip_ws(source, 0)
  if start >= source.length() {
    return ("", "")
  }
  let mut end = start
  while end < source.length() {
    match char_at(source, end) {
      Some(ch) => if is_ws(ch) { break } else { end += 1 }
      None => break
    }
  }
  (source[start:end].to_owned(), source[end:].to_owned())
}

///|
fn tokens(source : String) -> Array[String] {
  let result : Array[String] = []
  let mut i = 0
  while i < source.length() {
    i = skip_ws(source, i)
    if i >= source.length() {
      break
    }
    let start = i
    while i < source.length() {
      match char_at(source, i) {
        Some(ch) => if is_ws(ch) { break } else { i += 1 }
        None => break
      }
    }
    result.push(source[start:i].to_owned())
  }
  result
}

///|
fn first_arg(arguments : String) -> String {
  let (token, _) = first_token(arguments)
  token
}

///|
fn contains_token(source : String, token : String) -> Bool {
  let target = token.to_lower()
  for part in tokens(source.to_lower()) {
    if part == target {
      return true
    }
  }
  false
}

///|
fn find_ignore_case(source : String, needle : String) -> Int? {
  source.to_lower().find(needle.to_lower())
}

///|
fn split_physical_lines(source : String) -> Array[String] {
  let result : Array[String] = []
  for part in source.split("\n") {
    result.push(part.trim_end(chars="\r").to_owned())
  }
  result
}

///|
fn json_escape(value : String) -> String {
  let out = StringBuilder()
  for ch in value {
    match ch {
      '"' => out.write_string("\\\"")
      '\\' => out.write_string("\\\\")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      _ => out.write_char(ch)
    }
  }
  out.to_string()
}
