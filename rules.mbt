///|
fn diagnostic(
  code : String,
  level : String,
  line : Int,
  message : String,
) -> Diagnostic {
  { code, level, line, message, stage: None }
}

///|
fn stage_at(doc : Dockerfile, line : Int) -> String? {
  for inst in doc.instructions {
    if inst.line == line {
      return inst.stage
    }
  }
  if doc.instructions.length() > 0 {
    doc.instructions[doc.instructions.length() - 1].stage
  } else {
    None
  }
}

///|
fn with_stage(item : Diagnostic, doc : Dockerfile) -> Diagnostic {
  {
    code: item.code,
    level: item.level,
    line: item.line,
    message: item.message,
    stage: stage_at(doc, item.line),
  }
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
fn copy_paths(arguments : String) -> Array[String] {
  let result : Array[String] = []
  let parts = tokens(arguments)
  let mut i = 0
  while i < parts.length() {
    if parts[i].has_prefix("--") {
      if !parts[i].contains("=") && i + 1 < parts.length() {
        i += 2
      } else {
        i += 1
      }
    } else {
      result.push(parts[i])
      i += 1
    }
  }
  result
}

///|
fn has_npm_install(arguments : String) -> Bool {
  find_ignore_case(arguments, "npm install") is Some(_) ||
  find_ignore_case(arguments, "npm i ") is Some(_)
}

///|
fn stage_index_of(value : String) -> Int? {
  let n = @string.parse_int(value) catch { _ => return None }
  if n >= 0 {
    Some(n)
  } else {
    None
  }
}

///|
fn check_copy_from(
  inst : Instruction,
  named_stages : Array[String],
  current_index : Int,
  diagnostics : Array[Diagnostic],
) -> Unit {
  match inst.copy_from {
    None => ()
    Some(from) => {
      let current_name = inst.stage.unwrap_or("")
      let refers_self = (from == current_name && current_name != "") ||
        (stage_index_of(from) is Some(index) && index == current_index)
      if refers_self {
        diagnostics.push(
          diagnostic(
            "DL3023",
            "error",
            inst.line,
            "COPY --from cannot reference its own FROM alias.",
          ),
        )
        return
      }
      let mut known = false
      for name in named_stages {
        if name == from {
          known = true
        }
      }
      match stage_index_of(from) {
        Some(index) => if index >= 0 && index < current_index { known = true }
        None => ()
      }
      if !known {
        diagnostics.push(
          diagnostic(
            "DL3022",
            "error",
            inst.line,
            "COPY --from should reference a previously defined FROM alias.",
          ),
        )
      }
    }
  }
}

///|
pub fn lint_dockerfile(doc : Dockerfile) -> LintResult {
  lint_dockerfile_with(doc, default_options())
}

///|
pub fn lint_dockerfile_with(
  doc : Dockerfile,
  options : LintOptions,
) -> LintResult {
  let diagnostics : Array[Diagnostic] = []
  let named_stages : Array[String] = []
  let mut prev_run = false
  let mut last_user : String? = None
  let mut last_user_line = 1
  let mut has_pipefail = false
  let mut current_index = -1
  let mut cmd_count = 0
  let mut entrypoint_count = 0
  let mut wget_line = 0
  let mut curl_line = 0
  for inst in doc.instructions {
    match inst.kind {
      From => {
        current_index += 1
        prev_run = false
        last_user = None
        last_user_line = inst.line
        has_pipefail = false
        cmd_count = 0
        entrypoint_count = 0
        match inst.stage {
          Some(name) => {
            check_unique_stage(name, named_stages, inst.line, diagnostics)
            named_stages.push(name)
          }
          None => ()
        }
        check_from(inst, options, diagnostics)
      }
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
      Copy => {
        check_copy_from(inst, named_stages, current_index, diagnostics)
        check_copy_dest(inst, diagnostics)
      }
      Add => {
        check_copy_from(inst, named_stages, current_index, diagnostics)
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
      Env => check_env(inst, diagnostics)
      Expose => check_expose(inst, diagnostics)
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
        if contains_token(inst.arguments, "wget") {
          wget_line = inst.line
        }
        if contains_token(inst.arguments, "curl") {
          curl_line = inst.line
        }
        check_run(inst, has_pipefail, diagnostics)
      }
      Cmd => {
        cmd_count += 1
        if cmd_count > 1 {
          diagnostics.push(
            diagnostic(
              "DL4003",
              "warning",
              inst.line,
              "Multiple CMD instructions found. Only the last one takes effect.",
            ),
          )
        }
        check_json_form(inst, diagnostics)
      }
      Entrypoint => {
        entrypoint_count += 1
        if entrypoint_count > 1 {
          diagnostics.push(
            diagnostic(
              "DL4004",
              "error",
              inst.line,
              "Multiple ENTRYPOINT instructions found.",
            ),
          )
        }
        check_json_form(inst, diagnostics)
      }
      _ => ()
    }
    prev_run = inst.kind is Run
  }
  if wget_line > 0 && curl_line > 0 {
    diagnostics.push(
      diagnostic(
        "DL4001", "warning", curl_line, "Either use Wget or Curl but not both.",
      ),
    )
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
  let kept : Array[Diagnostic] = []
  for item in diagnostics {
    if !is_suppressed(item, doc, options) {
      kept.push(with_stage(item, doc))
    }
  }
  { diagnostics: kept, instruction_count: doc.instructions.length() }
}

///|
fn is_suppressed(
  item : Diagnostic,
  doc : Dockerfile,
  options : LintOptions,
) -> Bool {
  if contains_code(options.ignored, item.code) {
    return true
  }
  for inst in doc.instructions {
    if inst.line == item.line && contains_code(inst.ignored_codes, item.code) {
      return true
    }
  }
  false
}

///|
fn check_from(
  inst : Instruction,
  options : LintOptions,
  diagnostics : Array[Diagnostic],
) -> Unit {
  match parse_from_image(inst.arguments) {
    None =>
      diagnostics.push(
        diagnostic("DL3006", "error", inst.line, "FROM is missing an image."),
      )
    Some(image) => {
      if is_scratch(image.name) || is_variable_ref(image.name) {
        return
      }
      if inst.arguments.contains("--platform") {
        diagnostics.push(
          diagnostic(
            "DL3029",
            "warning",
            inst.line,
            "Do not use --platform= with FROM. Use build arguments or the build command instead.",
          ),
        )
      }
      if options.trusted_registries.length() > 0 {
        let registry = image_registry(image.name)
        if !contains_code(options.trusted_registries, registry) {
          diagnostics.push(
            diagnostic(
              "DL3026",
              "error",
              inst.line,
              "Use only an allowed registry: \{registry} is not trusted.",
            ),
          )
        }
      }
      if image.digest {
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
fn check_json_form(inst : Instruction, diagnostics : Array[Diagnostic]) -> Unit {
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
}

///|
fn check_copy_dest(inst : Instruction, diagnostics : Array[Diagnostic]) -> Unit {
  if inst.form is Json {
    return
  }
  let paths = copy_paths(inst.arguments)
  if paths.length() >= 3 {
    let dest = paths[paths.length() - 1]
    if !dest.has_suffix("/") && !dest.has_suffix("\\") {
      diagnostics.push(
        diagnostic(
          "DL3021",
          "error",
          inst.line,
          "COPY with more than two arguments requires the last argument to end with /",
        ),
      )
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
  if contains_token(inst.arguments, "cd") {
    diagnostics.push(
      diagnostic(
        "DL3003",
        "warning",
        inst.line,
        "Use WORKDIR to switch to a directory.",
      ),
    )
  }
  if has_npm_install(inst.arguments) &&
    packages_unpinned(install_packages(inst.arguments, "npm install")) {
    diagnostics.push(
      diagnostic(
        "DL3016",
        "warning",
        inst.line,
        "Pin versions in npm. Use package@version.",
      ),
    )
  }
  if contains_token(inst.arguments, "apt") &&
    !contains_token(inst.arguments, "apt-get") &&
    !contains_token(inst.arguments, "apt-cache") {
    diagnostics.push(
      diagnostic(
        "DL3027",
        "warning",
        inst.line,
        "Do not use apt as it is meant to be an end-user tool. Use apt-get or apt-cache.",
      ),
    )
  }
  if find_ignore_case(inst.arguments, "yum install") is Some(_) {
    if packages_unpinned(install_packages(inst.arguments, "yum install")) {
      diagnostics.push(
        diagnostic(
          "DL3033",
          "warning",
          inst.line,
          "Pin versions in yum install.",
        ),
      )
    }
    if !inst.arguments.contains("yum clean") {
      diagnostics.push(
        diagnostic(
          "DL3032",
          "warning",
          inst.line,
          "Use yum clean all after installing packages.",
        ),
      )
    }
  }
  if find_ignore_case(inst.arguments, "dnf install") is Some(_) {
    if packages_unpinned(install_packages(inst.arguments, "dnf install")) {
      diagnostics.push(
        diagnostic(
          "DL3041",
          "warning",
          inst.line,
          "Pin versions in dnf install.",
        ),
      )
    }
    if !inst.arguments.contains("dnf clean") {
      diagnostics.push(
        diagnostic(
          "DL3040",
          "warning",
          inst.line,
          "Use dnf clean all after installing packages.",
        ),
      )
    }
  }
  if find_ignore_case(inst.arguments, "gem install") is Some(_) &&
    packages_unpinned(install_packages(inst.arguments, "gem install")) {
    diagnostics.push(
      diagnostic(
        "DL3028",
        "warning",
        inst.line,
        "Pin versions in gem install. Use package:version.",
      ),
    )
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
