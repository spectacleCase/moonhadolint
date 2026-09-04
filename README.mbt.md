# MoonHadolint

MoonHadolint 是一个使用 MoonBit 编写的 Dockerfile 解析器与 hadolint 风格检查器。它读取 Dockerfile 文本，生成指令 AST，并按规则输出带行号的诊断。

本项目检查的是 **Dockerfile 写法**，不是镜像构建，也不是 OCI 布局：

- 不调用 Docker daemon，不构建镜像；
- 和 `oyjh0381/moonoci` 不同，本项目解析 Dockerfile，不读取 image layout；
- 和 `Lfan-ke/moonctl` 不同，本项目检查已有 Dockerfile，不生成脚手架；
- 和 ignore 包不同，本项目不处理 `.dockerignore` glob。

首版已经完成可运行 MVP：库 API、Native CLI、示例文件和自动化测试。

## 功能

- 解析常见 Dockerfile 指令：`FROM`、`RUN`、`COPY`、`ADD`、`WORKDIR`、`ENV`、`EXPOSE`、`USER`、`CMD`、`ENTRYPOINT` 等；
- 支持注释、空行和 `\` 续行；
- 识别 `FROM` 标签、digest、registry 端口和 `AS` 别名；
- 检查未打标签、`:latest`、相对 WORKDIR、root USER、`sudo`、包版本未固定、ADD 误用、连续 RUN 等问题；
- 输出 text / JSON 报告；
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
moon run --target native cmd/main -- parse examples/good.Dockerfile
```

## 命令

```text
moonhadolint lint  <Dockerfile>   检查文件并输出文本报告
moonhadolint json  <Dockerfile>   输出 JSON 诊断
moonhadolint parse <Dockerfile>   打印解析后的指令
moonhadolint sample               打印内置干净示例
moonhadolint bad-sample           打印内置问题示例
moonhadolint rules                列出当前 MVP 规则
```

文件路径写成 `-` 时，使用内置干净示例。直接传入 Dockerfile 路径时，默认执行 `lint`。

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

## 当前范围

MoonHadolint 首版有意保持聚焦：

- 只做本地 Dockerfile 文本的解析和规则检查；
- 覆盖高频指令和最有用的一批 hadolint 规则；
- 不是完整 shell 分析器，也不接入 ShellCheck；
- 不替代 Docker build、BuildKit 或镜像扫描工具。

规则编号与 [hadolint](https://github.com/hadolint/hadolint) 对齐，实现使用 MoonBit 重写，许可证为 Apache-2.0。

## 许可证

Apache-2.0
