///|
test "apt yum gem and wget curl rules" {
  let apt = @moonhadolint.lint_source(
    "FROM ubuntu:22.04\nRUN apt install curl\nUSER nobody\n",
  ).unwrap()
  assert_true(apt.has_code("DL3027"))
  let yum = @moonhadolint.lint_source(
    "FROM fedora:40\nRUN yum install httpd\nUSER nobody\n",
  ).unwrap()
  assert_true(yum.has_code("DL3033"))
  assert_true(yum.has_code("DL3032"))
  let mixed = @moonhadolint.lint_source(
    (
      #|FROM alpine:3.19
      #|RUN wget https://example.com
      #|RUN curl https://example.com
      #|USER nobody
      #|
    ),
  ).unwrap()
  assert_true(mixed.has_code("DL4001"))
  let platform = @moonhadolint.lint_source(
    "FROM --platform=linux/amd64 alpine:3.19\nUSER nobody\n",
  ).unwrap()
  assert_true(platform.has_code("DL3029"))
}
