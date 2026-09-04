///|
fn usage() -> Unit {
  println(
    (
      #|MoonHadolint v\{@moonhadolint.version}
      #|
      #|Usage:
      #|  moonhadolint lint <Dockerfile>
      #|  moonhadolint json <Dockerfile>
      #|  moonhadolint parse <Dockerfile>
      #|  moonhadolint sample
      #|  moonhadolint bad-sample
      #|  moonhadolint rules
      #|
      #|Use "-" as the file path to lint the built-in clean sample.
      #|A bare Dockerfile path is treated as lint.
    ),
  )
}

///|
fn load_source(path : String) -> Result[String, String] {
  if path == "-" {
    Ok(@moonhadolint.sample_dockerfile())
  } else {
    match read_file(path) {
      None => Err("cannot read file: \{path}")
      Some(text) => Ok(text)
    }
  }
}

///|
fn print_lint(path : String, as_json : Bool) -> Int {
  match load_source(path) {
    Err(message) => {
      println(message)
      1
    }
    Ok(source) =>
      match @moonhadolint.lint_source(source) {
        Err(error) => {
          println(error.to_string())
          1
        }
        Ok(result) => {
          if as_json {
            println(@moonhadolint.report_json(result))
          } else {
            println(@moonhadolint.report_text(result))
          }
          if result.has_errors() {
            1
          } else {
            0
          }
        }
      }
  }
}

///|
fn print_parse(path : String) -> Int {
  match load_source(path) {
    Err(message) => {
      println(message)
      1
    }
    Ok(source) =>
      match @moonhadolint.parse_dockerfile(source) {
        Err(error) => {
          println(error.to_string())
          1
        }
        Ok(doc) => {
          println(@moonhadolint.report_parse(doc))
          0
        }
      }
  }
}

///|
fn main {
  let args = @env.args()
  if args.length() < 2 || args[1] == "-h" || args[1] == "--help" {
    usage()
    return
  }
  if args[1] == "-V" || args[1] == "--version" {
    println(@moonhadolint.version)
    return
  }
  let code = match args[1] {
    "sample" => {
      println(@moonhadolint.sample_dockerfile())
      0
    }
    "bad-sample" => {
      println(@moonhadolint.sample_bad_dockerfile())
      0
    }
    "rules" => {
      println(@moonhadolint.report_rules())
      0
    }
    "lint" =>
      if args.length() < 3 {
        usage()
        1
      } else {
        print_lint(args[2], false)
      }
    "json" =>
      if args.length() < 3 {
        usage()
        1
      } else {
        print_lint(args[2], true)
      }
    "parse" =>
      if args.length() < 3 {
        usage()
        1
      } else {
        print_parse(args[2])
      }
    path => print_lint(path, false)
  }
  if code != 0 {
    exit_process(code)
  }
}
