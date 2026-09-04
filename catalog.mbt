///|
pub(all) struct RuleInfo {
  code : String
  level : String
  summary : String
} derive(Eq, Debug)

///|
pub fn all_rules() -> Array[RuleInfo] {
  [
    { code: "DL3000", level: "error", summary: "Use absolute WORKDIR" },
    {
      code: "DL3002",
      level: "warning",
      summary: "Last USER should not be root",
    },
    { code: "DL3003", level: "warning", summary: "Use WORKDIR instead of cd" },
    { code: "DL3004", level: "error", summary: "Do not use sudo" },
    { code: "DL3005", level: "error", summary: "Do not use apt-get upgrade" },
    { code: "DL3006", level: "error", summary: "Always tag FROM images" },
    { code: "DL3007", level: "warning", summary: "Avoid :latest" },
    {
      code: "DL3008",
      level: "warning",
      summary: "Pin apt-get package versions",
    },
    { code: "DL3009", level: "warning", summary: "Clean apt-get lists" },
    { code: "DL3011", level: "error", summary: "EXPOSE ports must be 0-65535" },
    { code: "DL3013", level: "warning", summary: "Pin pip package versions" },
    { code: "DL3014", level: "warning", summary: "Use apt-get -y" },
    { code: "DL3015", level: "warning", summary: "Use --no-install-recommends" },
    { code: "DL3016", level: "warning", summary: "Pin npm package versions" },
    { code: "DL3018", level: "warning", summary: "Pin apk package versions" },
    { code: "DL3019", level: "warning", summary: "Use apk --no-cache" },
    { code: "DL3020", level: "error", summary: "Prefer COPY over ADD" },
    {
      code: "DL3021",
      level: "error",
      summary: "Multi-source COPY dest must end with /",
    },
    {
      code: "DL3022",
      level: "error",
      summary: "COPY --from must name a prior stage",
    },
    {
      code: "DL3023",
      level: "error",
      summary: "COPY --from cannot target its own stage",
    },
    { code: "DL3024", level: "error", summary: "FROM aliases must be unique" },
    { code: "DL3025", level: "warning", summary: "Use JSON CMD/ENTRYPOINT" },
    { code: "DL3026", level: "error", summary: "Use only an allowed registry" },
    { code: "DL3027", level: "warning", summary: "Use apt-get instead of apt" },
    { code: "DL3028", level: "warning", summary: "Pin gem package versions" },
    { code: "DL3029", level: "warning", summary: "Avoid FROM --platform" },
    { code: "DL3032", level: "warning", summary: "Use yum clean all" },
    { code: "DL3033", level: "warning", summary: "Pin yum package versions" },
    { code: "DL3040", level: "warning", summary: "Use dnf clean all" },
    { code: "DL3041", level: "warning", summary: "Pin dnf package versions" },
    { code: "DL3042", level: "warning", summary: "Use pip --no-cache-dir" },
    { code: "DL3044", level: "warning", summary: "Do not use empty ENV values" },
    { code: "DL3048", level: "warning", summary: "Invalid LABEL key" },
    { code: "DL3049", level: "warning", summary: "Required LABEL is missing" },
    { code: "DL3059", level: "warning", summary: "Combine consecutive RUN" },
    { code: "DL4000", level: "error", summary: "MAINTAINER is deprecated" },
    { code: "DL4001", level: "warning", summary: "Do not mix wget and curl" },
    { code: "DL4003", level: "warning", summary: "Multiple CMD instructions" },
    {
      code: "DL4004",
      level: "error",
      summary: "Multiple ENTRYPOINT instructions",
    },
    { code: "DL4006", level: "warning", summary: "Set pipefail before pipes" },
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
