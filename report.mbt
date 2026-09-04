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
  let rules = all_rules()
  let out = StringBuilder()
  out.write_string("MoonHadolint rules (\{rules.length()})\n")
  out.write_string("======================\n")
  for rule in rules {
    out.write_string("\{rule.code}  \{rule.level}    \{rule.summary}\n")
  }
  out.to_string()
}
