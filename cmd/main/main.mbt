///|
fn usage() -> Unit {
  println(
    (
      #|MoonHadolint v\{@moonhadolint.version}
      #|
      #|Usage:
      #|  moonhadolint lint     [--ignore CODE] [--config FILE] [--threshold LEVEL] <Dockerfile>
      #|  moonhadolint json     [--ignore CODE] [--config FILE] [--threshold LEVEL] <Dockerfile>
      #|  moonhadolint annotate [--ignore CODE] [--config FILE] [--threshold LEVEL] <Dockerfile>
      #|  moonhadolint parse    <Dockerfile>
      #|  moonhadolint sample
      #|  moonhadolint bad-sample
      #|  moonhadolint rules
      #|
      #|Use "-" to read a Dockerfile from stdin.
      #|--threshold is error (default), warning, or never.
      #|A bare Dockerfile path is treated as lint.
      #|Inline comments like `# hadolint ignore=DL3006` suppress the next instruction.
    ),
  )
}

///|
fn load_source(path : String) -> Result[String, String] {
  if path == "-" {
    Ok(read_stdin())
  } else {
    match read_file(path) {
      None => Err("cannot read file: \{path}")
      Some(text) => Ok(text)
    }
  }
}

///|
fn load_options(
  config_path : String?,
  ignore_arg : String?,
) -> Result[@moonhadolint.LintOptions, String] {
  let mut options = @moonhadolint.default_options()
  match config_path {
    None => ()
    Some(path) =>
      match read_file(path) {
        None => return Err("cannot read config: \{path}")
        Some(text) => options = @moonhadolint.parse_config(text)
      }
  }
  match ignore_arg {
    None => ()
    Some(text) => {
      let extra = @moonhadolint.parse_config("ignored: \{text}")
      for code in extra.ignored {
        options.ignored.push(code)
      }
    }
  }
  Ok(options)
}

///|
fn take_flag(args : Array[String], index : Int, name : String) -> String? {
  if args[index] == name && index + 1 < args.length() {
    Some(args[index + 1])
  } else if args[index].has_prefix("\{name}=") {
    Some(args[index][name.length() + 1:].to_owned())
  } else {
    None
  }
}

///|
fn parse_lint_args(
  args : Array[String],
  start : Int,
) -> Result[(String, String?, String?, String), String] {
  let mut path : String? = None
  let mut ignore : String? = None
  let mut config : String? = None
  let mut threshold = "error"
  let mut i = start
  while i < args.length() {
    match take_flag(args, i, "--ignore") {
      Some(value) => {
        ignore = Some(value)
        i += if args[i] == "--ignore" { 2 } else { 1 }
        continue
      }
      None => ()
    }
    match take_flag(args, i, "--config") {
      Some(value) => {
        config = Some(value)
        i += if args[i] == "--config" { 2 } else { 1 }
        continue
      }
      None => ()
    }
    match take_flag(args, i, "--threshold") {
      Some(value) => {
        threshold = value
        i += if args[i] == "--threshold" { 2 } else { 1 }
        continue
      }
      None => ()
    }
    if args[i].has_prefix("-") && args[i] != "-" {
      return Err("unknown option: \{args[i]}")
    }
    path = Some(args[i])
    i += 1
  }
  match path {
    None => Err("missing Dockerfile path")
    Some(file) => Ok((file, ignore, config, threshold))
  }
}

///|
fn print_lint(
  path : String,
  format : String,
  options : @moonhadolint.LintOptions,
  threshold : String,
) -> Int {
  match load_source(path) {
    Err(message) => {
      println(message)
      1
    }
    Ok(source) =>
      match @moonhadolint.lint_source_with(source, options) {
        Err(error) => {
          println(error.to_string())
          1
        }
        Ok(result) => {
          match format {
            "json" => println(@moonhadolint.report_json(result))
            "github" => println(@moonhadolint.report_github(result, path~))
            _ => println(@moonhadolint.report_text(result))
          }
          if result.should_fail(threshold) {
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
fn run_lint(args : Array[String], start : Int, format : String) -> Int {
  match parse_lint_args(args, start) {
    Err(message) => {
      println(message)
      1
    }
    Ok((path, ignore, config, threshold)) =>
      match load_options(config, ignore) {
        Err(message) => {
          println(message)
          1
        }
        Ok(options) => print_lint(path, format, options, threshold)
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
    "lint" => run_lint(args, 2, "text")
    "json" => run_lint(args, 2, "json")
    "annotate" => run_lint(args, 2, "github")
    "parse" =>
      if args.length() < 3 {
        usage()
        1
      } else {
        print_parse(args[2])
      }
    _ => run_lint(args, 1, "text")
  }
  if code != 0 {
    exit_process(code)
  }
}
