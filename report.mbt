///|
pub fn report_text(result : LintResult) -> String {
  let out = StringBuilder()
  out.write_string("MoonHadolint report\n")
  out.write_string("===================\n\n")
  out.write_string("instructions: \{result.instruction_count}\n")
  out.write_string("errors: \{result.error_count()}\n")
  out.write_string("warnings: \{result.warning_count()}\n")
  if result.diagnostics.length() == 0 {
    out.write_string("\nNo issues found.\n")
  } else {
    out.write_string("\n")
    for item in result.diagnostics {
      let stage = match item.stage {
        None => ""
        Some(name) => " [\{name}]"
      }
      out.write_string(
        "\{item.level}: \{item.code} at line \{item.line}\{stage}: \{item.message}\n",
      )
    }
  }
  out.to_string()
}

///|
pub fn report_json(result : LintResult) -> String {
  let out = StringBuilder()
  out.write_string("{\n")
  let ok = if result.has_errors() { "false" } else { "true" }
  out.write_string("  \"ok\": \{ok},\n")
  out.write_string("  \"instructionCount\": \{result.instruction_count},\n")
  out.write_string("  \"errorCount\": \{result.error_count()},\n")
  out.write_string("  \"warningCount\": \{result.warning_count()},\n")
  out.write_string("  \"diagnostics\": [\n")
  let last = result.diagnostics.length() - 1
  let mut i = 0
  for item in result.diagnostics {
    let comma = if i == last { "" } else { "," }
    let stage_json = match item.stage {
      None => "null"
      Some(name) => "\"\{json_escape(name)}\""
    }
    out.write_string(
      "    {\"code\": \"\{json_escape(item.code)}\", \"level\": \"\{json_escape(item.level)}\", \"line\": \{item.line}, \"stage\": \{stage_json}, \"message\": \"\{json_escape(item.message)}\"}\{comma}\n",
    )
    i += 1
  }
  out.write_string("  ]\n")
  out.write_string("}\n")
  out.to_string()
}

///|
pub fn report_github(
  result : LintResult,
  path? : String = "Dockerfile",
) -> String {
  let out = StringBuilder()
  for item in result.diagnostics {
    let kind = if item.level == "error" { "error" } else { "warning" }
    out.write_string(
      "::\{kind} file=\{path},line=\{item.line}::\{item.code} \{item.message}\n",
    )
  }
  if result.diagnostics.length() == 0 {
    out.write_string("No issues found.\n")
  }
  out.to_string()
}

///|
pub fn report_parse(doc : Dockerfile) -> String {
  let out = StringBuilder()
  if doc.instructions.length() == 0 {
    out.write_string("no instructions\n")
  } else {
    for inst in doc.instructions {
      out.write_string(
        "\{inst.line} \{inst.name.to_upper()} \{inst.arguments}\n",
      )
    }
  }
  out.to_string()
}

///|
pub fn report_rules() -> String {
  let out = StringBuilder()
  out.write_string("MoonHadolint MVP rules\n")
  out.write_string("======================\n")
  out.write_string("DL3000  error    Use absolute WORKDIR\n")
  out.write_string("DL3002  warning  Last USER should not be root\n")
  out.write_string("DL3003  warning  Use WORKDIR instead of cd\n")
  out.write_string("DL3004  error    Do not use sudo\n")
  out.write_string("DL3005  error    Do not use apt-get upgrade\n")
  out.write_string("DL3006  error    Always tag FROM images\n")
  out.write_string("DL3007  warning  Avoid :latest\n")
  out.write_string("DL3008  warning  Pin apt-get package versions\n")
  out.write_string("DL3009  warning  Clean apt-get lists\n")
  out.write_string("DL3011  error    EXPOSE ports must be 0-65535\n")
  out.write_string("DL3013  warning  Pin pip package versions\n")
  out.write_string("DL3014  warning  Use apt-get -y\n")
  out.write_string("DL3015  warning  Use --no-install-recommends\n")
  out.write_string("DL3016  warning  Pin npm package versions\n")
  out.write_string("DL3018  warning  Pin apk package versions\n")
  out.write_string("DL3019  warning  Use apk --no-cache\n")
  out.write_string("DL3020  error    Prefer COPY over ADD\n")
  out.write_string("DL3021  error    Multi-source COPY dest must end with /\n")
  out.write_string("DL3022  error    COPY --from must name a prior stage\n")
  out.write_string("DL3023  error    COPY --from cannot target its own stage\n")
  out.write_string("DL3024  error    FROM aliases must be unique\n")
  out.write_string("DL3025  warning  Use JSON CMD/ENTRYPOINT\n")
  out.write_string("DL3026  error    Use only an allowed registry\n")
  out.write_string("DL3027  warning  Use apt-get instead of apt\n")
  out.write_string("DL3028  warning  Pin gem package versions\n")
  out.write_string("DL3029  warning  Avoid FROM --platform\n")
  out.write_string("DL3032  warning  Use yum clean all\n")
  out.write_string("DL3033  warning  Pin yum package versions\n")
  out.write_string("DL3040  warning  Use dnf clean all\n")
  out.write_string("DL3041  warning  Pin dnf package versions\n")
  out.write_string("DL3042  warning  Use pip --no-cache-dir\n")
  out.write_string("DL3044  warning  Do not use empty ENV values\n")
  out.write_string("DL3059  warning  Combine consecutive RUN\n")
  out.write_string("DL4000  error    MAINTAINER is deprecated\n")
  out.write_string("DL4001  warning  Do not mix wget and curl\n")
  out.write_string("DL4003  warning  Multiple CMD instructions\n")
  out.write_string("DL4004  error    Multiple ENTRYPOINT instructions\n")
  out.write_string("DL4006  warning  Set pipefail before pipes\n")
  out.to_string()
}
