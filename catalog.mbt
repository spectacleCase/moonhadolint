///|
pub(all) struct RuleInfo {
  code : String
  level : String
  summary : String
} derive(Eq, Debug)

///|
pub extend RuleInfo with Eq::{not_equal, equal}

///|
pub extend RuleInfo with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub fn all_rules() -> Array[RuleInfo] {
  [
    { code: "DL3000", level: "error", summary: "Require absolute WORKDIR", },
    {
      code: "DL3002",
      level: "warning",
      summary: "Final USER resolves to root",
    },
    { code: "DL3003", level: "warning", summary: "Prefer WORKDIR over cd", },
    { code: "DL3004", level: "error", summary: "Avoid sudo in RUN", },
    { code: "DL3005", level: "error", summary: "Avoid distribution upgrades", },
    { code: "DL3006", level: "error", summary: "Pin base image identity", },
    { code: "DL3007", level: "warning", summary: "Floating latest tag", },
    {
      code: "DL3008",
      level: "warning",
      summary: "Unpinned apt package",
    },
    { code: "DL3009", level: "warning", summary: "Apt list cache remains", },
    { code: "DL3011", level: "error", summary: "Invalid EXPOSE port", },
    { code: "DL3013", level: "warning", summary: "Unpinned pip package", },
    { code: "DL3014", level: "warning", summary: "Apt install may prompt", },
    {
      code: "DL3015",
      level: "warning",
      summary: "Recommended apt packages enabled",
    },
    { code: "DL3016", level: "warning", summary: "Unpinned npm package", },
    { code: "DL3018", level: "warning", summary: "Unpinned apk package", },
    { code: "DL3019", level: "warning", summary: "Apk index cache retained", },
    { code: "DL3020", level: "error", summary: "Local ADD can be COPY", },
    {
      code: "DL3021",
      level: "error",
      summary: "Multi-source COPY needs directory dest",
    },
    {
      code: "DL3022",
      level: "error",
      summary: "Unknown COPY --from stage",
    },
    {
      code: "DL3023",
      level: "error",
      summary: "Self-referencing COPY --from",
    },
    { code: "DL3024", level: "error", summary: "Duplicate FROM alias", },
    { code: "DL3025", level: "warning", summary: "Shell-form CMD or ENTRYPOINT", },
    { code: "DL3026", level: "error", summary: "Registry outside allowlist", },
    { code: "DL3027", level: "warning", summary: "Script uses apt frontend", },
    { code: "DL3028", level: "warning", summary: "Unpinned gem package", },
    { code: "DL3029", level: "warning", summary: "Fixed platform in FROM", },
    { code: "DL3032", level: "warning", summary: "Yum metadata remains", },
    { code: "DL3033", level: "warning", summary: "Unpinned yum package", },
    { code: "DL3040", level: "warning", summary: "Dnf metadata remains", },
    { code: "DL3041", level: "warning", summary: "Unpinned dnf package", },
    { code: "DL3042", level: "warning", summary: "Pip cache retained", },
    {
      code: "DL3044",
      level: "warning",
      summary: "Empty ENV value",
    },
    { code: "DL3048", level: "warning", summary: "Unsupported LABEL key shape", },
    { code: "DL3049", level: "warning", summary: "Configured LABEL absent", },
    { code: "DL3059", level: "warning", summary: "Adjacent RUN instructions", },
    { code: "DL4000", level: "error", summary: "Legacy MAINTAINER instruction", },
    { code: "DL4001", level: "warning", summary: "Mixed download tools", },
    { code: "DL4003", level: "warning", summary: "Extra CMD instruction", },
    {
      code: "DL4004",
      level: "error",
      summary: "Extra ENTRYPOINT instruction",
    },
    { code: "DL4006", level: "warning", summary: "Pipefail missing for RUN pipe", },
    {
      code: "DL3061",
      level: "error",
      summary: "Unsupported first instruction",
    },
    {
      code: "SC2046",
      level: "warning",
      summary: "Unquoted command substitution",
    },
    { code: "SC2068", level: "warning", summary: "Unquoted argument expansion", },
    {
      code: "SC2086",
      level: "warning",
      summary: "Unquoted variable expansion",
    },
    { code: "SC2164", level: "warning", summary: "Unchecked cd result", },
  ]
}

///|
pub fn has_rule(code : String) -> Bool {
  for rule in all_rules() {
    if rule.code == code {
      return true
    }
  }
  false
}
