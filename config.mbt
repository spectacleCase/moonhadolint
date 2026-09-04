///|
fn split_codes(text : String) -> Array[String] {
  let result : Array[String] = []
  let normalized = text
    .replace(old="[", new=" ")
    .replace(old="]", new=" ")
    .replace(old=",", new=" ")
  for part in tokens(normalized) {
    if !part.is_empty() {
      result.push(part.to_upper())
    }
  }
  result
}

///|
fn parse_ignore_comment(text : String) -> Array[String]? {
  let body = match text.trim().strip_prefix("#") {
    None => return None
    Some(rest) => rest.trim().to_owned()
  }
  let lower = body.to_lower()
  if lower.has_prefix("hadolint ignore=") ||
    lower.has_prefix("moonhadolint ignore=") {
    match body.find("=") {
      None => None
      Some(eq) => Some(split_codes(body[eq + 1:].to_owned()))
    }
  } else {
    None
  }
}

///|
fn contains_code(codes : Array[String], code : String) -> Bool {
  for item in codes {
    if item.equal_ignore_ascii_case(code) {
      return true
    }
  }
  false
}

///|
pub fn parse_config(source : String) -> LintOptions {
  let ignored : Array[String] = []
  let trusted : Array[String] = []
  let required : Array[String] = []
  let mut section = ""
  for line in split_physical_lines(source) {
    let text = line.trim().to_owned()
    if text.is_empty() || text.has_prefix("#") {
      continue
    }
    if text.has_prefix("ignored:") {
      section = "ignored"
      let rest = text[8:].trim().to_owned()
      if !rest.is_empty() {
        for code in split_codes(rest) {
          ignored.push(code)
        }
      }
      continue
    }
    if text.has_prefix("requiredLabels:") || text.has_prefix("required:") {
      section = "required"
      let prefix = if text.has_prefix("requiredLabels:") { 15 } else { 9 }
      let rest = text[prefix:].trim().to_owned()
      if !rest.is_empty() {
        for
          item in tokens(
            rest
            .replace(old="[", new=" ")
            .replace(old="]", new=" ")
            .replace(old=",", new=" "),
          ) {
          required.push(item)
        }
      }
      continue
    }
    if text.has_prefix("trustedRegistries:") || text.has_prefix("trusted:") {
      section = "trusted"
      let prefix = if text.has_prefix("trustedRegistries:") { 18 } else { 8 }
      let rest = text[prefix:].trim().to_owned()
      if !rest.is_empty() {
        for item in split_codes(rest) {
          trusted.push(item.to_lower())
        }
      }
      continue
    }
    if text.has_prefix("-") {
      let item = text[1:].trim().to_owned()
      if item.is_empty() {
        continue
      }
      if section == "ignored" {
        ignored.push(item.to_upper())
      } else if section == "trusted" {
        trusted.push(item.to_lower())
      } else if section == "required" {
        required.push(item)
      }
    }
  }
  { ignored, trusted_registries: trusted, required_labels: required }
}
