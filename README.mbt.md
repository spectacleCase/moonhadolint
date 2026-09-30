# MoonHadolint

MoonHadolint 是一个使用 MoonBit 编写的 Dockerfile 解析器与 hadolint 风格检查器。它读取 Dockerfile 文本，生成指令 AST，并按规则输出带行号的诊断。

本项目检查的是 **Dockerfile 写法**，不是镜像构建，也不是 OCI 布局：

- 不调用 Docker daemon，不构建镜像；
- 和 `oyjh0381/moonoci` 不同，本项目解析 Dockerfile，不读取 image layout；
- 和 `Lfan-ke/moonctl` 不同，本项目检查已有 Dockerfile，不生成脚手架；
- 和 ignore 包不同，本项目不处理 `.dockerignore` glob。

## 边界与关系说明（规避重复）

MoonHadolint 的目标是“**Dockerfile 质量检查器**”，而不是通用语法基础设施：

- 不提供通用的语法树增量更新能力（如 `Syntax tree / highlighter` 套件）；
- 不提供编辑器级 tokenization、高亮、代码动作补全、语法树遍历 API；
- 不提供语言服务器或构建编译流水线能力；
- 不重建或依赖外部镜像布局，不替代 `mooncakes.io` 生态中的通用解析器/高亮器。

它的输入是 Dockerfile 文本，输出是带规则码（DL/SC）、行号和严重级别的 linter 诊断；默认产物偏向 CI 检测与质量治理场景。`mooncakes.io/mizchi/syntree`（0.2.4）更偏通用语法树与高亮工具链，二者是互补关系而非替代关系。

首版已经完成可运行 MVP：库 API、Native CLI、示例文件和自动化测试。

## 功能

- 解析常见 Dockerfile 指令：`FROM`、`RUN`、`COPY`、`ADD`、`WORKDIR`、`ENV`、`EXPOSE`、`USER`、`CMD`、`ENTRYPOINT` 等；
- 支持注释、空行和 `\` 续行；
- 识别 `FROM` 标签、digest、registry 端口、`AS` 别名和 `COPY --from`；
- 支持 `# hadolint ignore=`、`--ignore` 和小型配置文件；
- 检查未打标签、`:latest`、相对 WORKDIR、root USER、`sudo`、包版本未固定、ADD 误用、连续 RUN、未知 stage 等问题；
- 输出 text / JSON / GitHub annotations 报告；
- 存在 error 级诊断时，CLI 返回非 0 退出码。

## 快速开始

作为 MoonBit 库依赖安装：

```bash
moon add spectacleCase/moonhadolint
```

使用 Native CLI：

```bash
moon test
moon run --target native cmd/main -- sample
moon run --target native cmd/main -- lint -
moon run --target native cmd/main -- json examples/bad.Dockerfile
moon run --target native cmd/main -- annotate examples/bad.Dockerfile
moon run --target native cmd/main -- lint --ignore DL3006 examples/bad.Dockerfile
moon run --target native cmd/main -- parse examples/good.Dockerfile
moon run --target native cmd/main -- lint examples/multistage.Dockerfile
```

## 命令

```text
moonhadolint lint     [--ignore CODE] [--config FILE] <Dockerfile>
moonhadolint json     [--ignore CODE] [--config FILE] <Dockerfile>
moonhadolint annotate [--ignore CODE] [--config FILE] <Dockerfile>
moonhadolint parse    <Dockerfile>
moonhadolint sample
moonhadolint bad-sample
moonhadolint rules
```

文件路径写成 `-` 时从标准输入读取。直接传入 Dockerfile 路径时，默认执行 `lint`。`--threshold` 可以是 `error`、`warning` 或 `never`。

## 库 API

```mbt check
///|
test "lint clean sample" {
  let result = @moonhadolint.lint_source(@moonhadolint.sample_dockerfile()).unwrap()
  inspect(result.diagnostics.length(), content="0")
  inspect(result.instruction_count, content="6")
}
```

```mbt check
///|
test "parse FROM line" {
  let doc = @moonhadolint.parse_dockerfile("FROM alpine:3.19\n").unwrap()
  assert_true(doc.instructions[0].kind is From)
  inspect(doc.instructions[0].arguments, content="alpine:3.19")
}
```

## 规则

当前内置 45 条规则（含 4 条高频 shell 子集，编号对齐 ShellCheck），可用 `moonhadolint rules` 列出。覆盖镜像标签、多阶段 `COPY --from`、包管理器、USER/WORKDIR、LABEL、CMD/ENTRYPOINT，以及对 `RUN` 中未加引号的变量和未保护的 `cd`。

```mbt check
///|
test "catalog includes FROM tag rule" {
  assert_true(@moonhadolint.has_rule("DL3006"))
}
```

## 当前范围

MoonHadolint 首版有意保持聚焦：

- 只做本地 Dockerfile 文本的解析和规则检查；
- 覆盖高频指令和最有用的一批 hadolint 规则；
- 对 `RUN` 只做高频 shell 子集（SC2086 / SC2046 / SC2068 / SC2164），不是完整 ShellCheck；
- 不替代 Docker build、BuildKit 或镜像扫描工具。

规则编号与 [hadolint](https://github.com/hadolint/hadolint) 对齐，实现使用 MoonBit 重写，许可证为 Apache-2.0。

## 许可证

Apache-2.0
