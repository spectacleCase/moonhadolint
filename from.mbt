///|
priv struct FromImage {
  name : String
  tag : String?
  digest : Bool
}

///|
fn parse_from_image(arguments : String) -> FromImage? {
  let parts = tokens(arguments)
  let mut image = ""
  let mut i = 0
  while i < parts.length() {
    let part = parts[i]
    if part.has_prefix("--") {
      i += 1
      continue
    }
    if part.equal_ignore_ascii_case("AS") {
      break
    }
    if image.is_empty() {
      image = part
    }
    i += 1
  }
  if image.is_empty() {
    None
  } else {
    Some(split_image_ref(image))
  }
}

///|
fn split_image_ref(image : String) -> FromImage {
  match image.find("@") {
    Some(_) => { name: image, tag: None, digest: true }
    None => {
      let slash = image.rev_find("/").unwrap_or(-1)
      match image.rev_find(":") {
        None => { name: image, tag: None, digest: false }
        Some(colon) =>
          if colon > slash {
            {
              name: image[:colon].to_owned(),
              tag: Some(image[colon + 1:].to_owned()),
              digest: false,
            }
          } else {
            { name: image, tag: None, digest: false }
          }
      }
    }
  }
}

///|
fn is_scratch(name : String) -> Bool {
  name.equal_ignore_ascii_case("scratch")
}

///|
fn is_variable_ref(name : String) -> Bool {
  name.has_prefix("$")
}
