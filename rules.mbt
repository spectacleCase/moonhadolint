///|
fn diagnostic(
  code : String,
  level : String,
  line : Int,
  message : String,
) -> Diagnostic {
  { code, level, line, message }
}

///|
fn install_packages(arguments : String, command : String) -> Array[String] {
  let result : Array[String] = []
  match find_ignore_case(arguments, command) {
    None => result
    Some(index) => {
      let rest = arguments[index + command.length():].to_owned()
      for part in tokens(rest) {
        if part == "&&" || part == "||" || part == ";" {
          break
        }
        if part.has_prefix("-") {
          continue
        }
        if part == "apt-get" ||
          part == "apt" ||
          part == "apk" ||
          part == "pip" ||
          part == "pip3" ||
          part == "install" ||
          part == "add" {
          break
        }
        result.push(part)
      }
      result
    }
  }
}

///|
fn packages_unpinned(packages : Array[String]) -> Bool {
  if packages.length() == 0 {
    return false
  }
  for pkg in packages {
    if !(pkg.contains("=") || pkg.contains("~") || pkg.contains("@")) {
      return true
    }
  }
  false
}

///|
fn add_is_local_file(arguments : String) -> Bool {
  let source = first_arg(arguments)
  if source.is_empty() || source.has_prefix("$") {
    return false
  }
  let lower = source.to_lower()
  if lower.has_prefix("http://") || lower.has_prefix("https://") {
    return false
  }
  if lower.has_suffix(".tar") ||
    lower.has_suffix(".tar.gz") ||
    lower.has_suffix(".tgz") ||
    lower.has_suffix(".tar.xz") ||
    lower.has_suffix(".tar.bz2") ||
    lower.has_suffix(".txz") ||
    lower.has_suffix(".zip") {
    return false
  }
  true
}

///|
fn workdir_is_absolute(arguments : String) -> Bool {
  let path = first_arg(arguments)
  if path.is_empty() || path.has_prefix("$") {
    return true
  }
  path.has_prefix("/") || (path.length() >= 2 && path.get_char(1) is Some(':'))
}

///|
fn has_apt_install(arguments : String) -> Bool {
  find_ignore_case(arguments, "apt-get install") is Some(_) ||
  find_ignore_case(arguments, "apt install") is Some(_)
}

///|
fn has_apk_add(arguments : String) -> Bool {
  find_ignore_case(arguments, "apk add") is Some(_)
}

///|
fn has_pip_install(arguments : String) -> Bool {
  find_ignore_case(arguments, "pip install") is Some(_) ||
  find_ignore_case(arguments, "pip3 install") is Some(_)
}

///|
pub fn lint_dockerfile(doc : Dockerfile) -> LintResult {
  let diagnostics : Array[Diagnostic] = []
  let mut prev_run = false
  let mut last_user : String? = None
  let mut last_user_line = 1
  let mut has_pipefail = false
  for inst in doc.instructions {
    match inst.kind {
      From => check_from(inst, diagnostics)
      Workdir =>
        if !workdir_is_absolute(inst.arguments) {
          diagnostics.push(
            diagnostic(
              "DL3000",
              "error",
              inst.line,
              "Use absolute WORKDIR. Changing directory with relative paths can produce unexpected results.",
            ),
          )
        }
      Add =>
        if add_is_local_file(inst.arguments) {
          diagnostics.push(
            diagnostic(
              "DL3020",
              "error",
              inst.line,
              "Use COPY instead of ADD for files and directories.",
            ),
          )
        }
      Maintainer =>
        diagnostics.push(
          diagnostic(
            "DL4000",
            "error",
            inst.line,
            "MAINTAINER is deprecated. Use LABEL instead.",
          ),
        )
      User => {
        last_user = Some(first_arg(inst.arguments))
        last_user_line = inst.line
      }
      Shell => if inst.arguments.contains("pipefail") { has_pipefail = true }
      Run => {
        if prev_run {
          diagnostics.push(
            diagnostic(
              "DL3059",
              "warning",
              inst.line,
              "Multiple consecutive RUN instructions. Combine them to reduce layers.",
            ),
          )
        }
        check_run(inst, has_pipefail, diagnostics)
      }
      Cmd | Entrypoint =>
        if !(inst.form is Json) {
          diagnostics.push(
            diagnostic(
              "DL3025",
              "warning",
              inst.line,
              "Use JSON notation for CMD and ENTRYPOINT arguments.",
            ),
          )
        }
      _ => ()
    }
    prev_run = inst.kind is Run
  }
  match last_user {
    None =>
      if doc.instructions.length() > 0 {
        diagnostics.push(
          diagnostic(
            "DL3002", "warning", 1, "Last USER should not be root. Add a non-root USER instruction.",
          ),
        )
      }
    Some(user) =>
      if user == "" || user.equal_ignore_ascii_case("root") || user == "0" {
        diagnostics.push(
          diagnostic(
            "DL3002", "warning", last_user_line, "Last USER should not be root.",
          ),
        )
      }
  }
  { diagnostics, instruction_count: doc.instructions.length() }
}

///|
fn check_from(inst : Instruction, diagnostics : Array[Diagnostic]) -> Unit {
  match parse_from_image(inst.arguments) {
    None =>
      diagnostics.push(
        diagnostic("DL3006", "error", inst.line, "FROM is missing an image."),
      )
    Some(image) => {
      if is_scratch(image.name) || is_variable_ref(image.name) || image.digest {
        return
      }
      match image.tag {
        None =>
          diagnostics.push(
            diagnostic(
              "DL3006",
              "error",
              inst.line,
              "Always tag the version of an image explicitly.",
            ),
          )
        Some(tag) =>
          if tag.equal_ignore_ascii_case("latest") {
            diagnostics.push(
              diagnostic(
                "DL3007",
                "warning",
                inst.line,
                "Using latest is prone to errors from image updates.",
              ),
            )
          }
      }
    }
  }
}

///|
fn check_run(
  inst : Instruction,
  has_pipefail : Bool,
  diagnostics : Array[Diagnostic],
) -> Unit {
  if contains_token(inst.arguments, "sudo") {
    diagnostics.push(
      diagnostic(
        "DL3004",
        "error",
        inst.line,
        "Do not use sudo as it leads to unpredictable behavior. Use a USER instruction instead.",
      ),
    )
  }
  if find_ignore_case(inst.arguments, "apt-get upgrade") is Some(_) ||
    find_ignore_case(inst.arguments, "apt-get dist-upgrade") is Some(_) ||
    find_ignore_case(inst.arguments, "apt upgrade") is Some(_) {
    diagnostics.push(
      diagnostic(
        "DL3005",
        "error",
        inst.line,
        "Do not use apt-get upgrade or dist-upgrade.",
      ),
    )
  }
  if has_apt_install(inst.arguments) {
    if !(contains_token(inst.arguments, "-y") ||
      contains_token(inst.arguments, "--yes") ||
      contains_token(inst.arguments, "--assume-yes")) {
      diagnostics.push(
        diagnostic(
          "DL3014",
          "warning",
          inst.line,
          "Use the -y switch to avoid manual input from apt-get.",
        ),
      )
    }
    if !inst.arguments.contains("--no-install-recommends") {
      diagnostics.push(
        diagnostic(
          "DL3015",
          "warning",
          inst.line,
          "Avoid additional packages by specifying --no-install-recommends.",
        ),
      )
    }
    if packages_unpinned(install_packages(inst.arguments, "apt-get install")) ||
      packages_unpinned(install_packages(inst.arguments, "apt install")) {
      diagnostics.push(
        diagnostic(
          "DL3008",
          "warning",
          inst.line,
          "Pin versions in apt-get install. Use package=version.",
        ),
      )
    }
    if !inst.arguments.contains("/var/lib/apt/lists") {
      diagnostics.push(
        diagnostic(
          "DL3009",
          "warning",
          inst.line,
          "Delete the apt-get lists after installing packages.",
        ),
      )
    }
  }
  if has_apk_add(inst.arguments) {
    if !inst.arguments.contains("--no-cache") {
      diagnostics.push(
        diagnostic(
          "DL3019",
          "warning",
          inst.line,
          "Use the --no-cache switch with apk add to avoid extra cache cleanup.",
        ),
      )
    }
    if packages_unpinned(install_packages(inst.arguments, "apk add")) {
      diagnostics.push(
        diagnostic(
          "DL3018",
          "warning",
          inst.line,
          "Pin versions in apk add. Use package=version.",
        ),
      )
    }
  }
  if has_pip_install(inst.arguments) {
    if packages_unpinned(install_packages(inst.arguments, "pip install")) ||
      packages_unpinned(install_packages(inst.arguments, "pip3 install")) {
      diagnostics.push(
        diagnostic(
          "DL3013",
          "warning",
          inst.line,
          "Pin versions in pip. Use package==version.",
        ),
      )
    }
    if !inst.arguments.contains("--no-cache-dir") {
      diagnostics.push(
        diagnostic(
          "DL3042",
          "warning",
          inst.line,
          "Avoid pip cache with --no-cache-dir.",
        ),
      )
    }
  }
  if inst.arguments.contains("|") && !has_pipefail {
    diagnostics.push(
      diagnostic(
        "DL4006",
        "warning",
        inst.line,
        "Set the SHELL option -o pipefail before RUN with a pipe.",
      ),
    )
  }
}
