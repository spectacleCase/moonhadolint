///|
fn parse_json_argv(source : String) -> Array[String]? {
  let text = source.trim().to_owned()
  if !text.has_prefix("[") || !text.has_suffix("]") {
    return None
  }
  let inner = text[1:text.length() - 1].to_owned()
  let result : Array[String] = []
  let mut i = skip_ws(inner, 0)
  if i >= inner.length() {
    return Some(result)
  }
  let mut expect_comma = false
  while i < inner.length() {
    i = skip_ws(inner, i)
    if i >= inner.length() {
      break
    }
    if expect_comma {
      if inner.get_char(i) is Some(',') {
        i += 1
        expect_comma = false
        continue
      } else {
        return None
      }
    }
    if !(inner.get_char(i) is Some('"')) {
      return None
    }
    i += 1
    let buf = StringBuilder()
    let mut closed = false
    while i < inner.length() {
      match inner.get_char(i) {
        None => return None
        Some('\\') => {
          if i + 1 >= inner.length() {
            return None
          }
          match inner.get_char(i + 1) {
            None => return None
            Some(ch) => buf.write_char(ch)
          }
          i += 2
        }
        Some('"') => {
          i += 1
          closed = true
          break
        }
        Some(ch) => {
          buf.write_char(ch)
          i += 1
        }
      }
    }
    if !closed {
      return None
    }
    result.push(buf.to_string())
    expect_comma = true
  }
  Some(result)
}
