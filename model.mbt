///|
pub let version : String = "0.1.0"

///|
pub(all) enum InstructionKind {
  From
  Run
  Cmd
  Entrypoint
  Copy
  Add
  Workdir
  Env
  Expose
  User
  Arg
  Label
  Volume
  Healthcheck
  Shell
  Maintainer
  Stopsignal
  Onbuild
  Unknown
} derive(Eq, Debug)

///|
pub(all) enum InstructionForm {
  Shell
  Json
  Other
} derive(Eq, Debug)

///|
pub(all) struct Instruction {
  kind : InstructionKind
  name : String
  arguments : String
  line : Int
  form : InstructionForm
  stage : String?
  copy_from : String?
  ignored_codes : Array[String]
} derive(Debug)

///|
pub(all) struct LintOptions {
  ignored : Array[String]
  trusted_registries : Array[String]
} derive(Debug)

///|
pub fn default_options() -> LintOptions {
  { ignored: [], trusted_registries: [] }
}

///|
pub(all) struct Dockerfile {
  instructions : Array[Instruction]
} derive(Debug)

///|
pub(all) struct Diagnostic {
  code : String
  level : String
  line : Int
  message : String
} derive(Eq, Debug)

///|
pub(all) struct LintResult {
  diagnostics : Array[Diagnostic]
  instruction_count : Int
} derive(Debug)

///|
pub(all) struct ParseError {
  line : Int
  message : String
}

///|
pub impl Show for ParseError with fn output(self, logger) {
  logger.write_string("parse error at line \{self.line}: \{self.message}")
}

///|
pub fn LintResult::error_count(self : LintResult) -> Int {
  let mut count = 0
  for item in self.diagnostics {
    if item.level == "error" {
      count += 1
    }
  }
  count
}

///|
pub fn LintResult::warning_count(self : LintResult) -> Int {
  let mut count = 0
  for item in self.diagnostics {
    if item.level == "warning" {
      count += 1
    }
  }
  count
}

///|
pub fn LintResult::has_errors(self : LintResult) -> Bool {
  self.error_count() > 0
}

///|
pub fn LintResult::has_code(self : LintResult, code : String) -> Bool {
  for item in self.diagnostics {
    if item.code == code {
      return true
    }
  }
  false
}

///|
fn kind_of(name : String) -> InstructionKind {
  match name.to_upper() {
    "FROM" => From
    "RUN" => Run
    "CMD" => Cmd
    "ENTRYPOINT" => Entrypoint
    "COPY" => Copy
    "ADD" => Add
    "WORKDIR" => Workdir
    "ENV" => Env
    "EXPOSE" => Expose
    "USER" => User
    "ARG" => Arg
    "LABEL" => Label
    "VOLUME" => Volume
    "HEALTHCHECK" => Healthcheck
    "SHELL" => Shell
    "MAINTAINER" => Maintainer
    "STOPSIGNAL" => Stopsignal
    "ONBUILD" => Onbuild
    _ => Unknown
  }
}

///|
fn form_of(arguments : String) -> InstructionForm {
  let trimmed = arguments.trim().to_owned()
  if trimmed.has_prefix("[") {
    Json
  } else if trimmed.is_empty() {
    Other
  } else {
    Shell
  }
}
