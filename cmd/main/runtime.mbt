///|
#borrow(path)
extern "c" fn file_exists_raw(path : Bytes) -> Int = "moonhadolint_file_exists"

///|
#borrow(path)
extern "c" fn read_file_raw(path : Bytes) -> Bytes = "moonhadolint_read_file"

///|
extern "c" fn read_stdin_raw() -> Bytes = "moonhadolint_read_stdin"

///|
extern "c" fn exit_raw(code : Int) -> Unit = "moonhadolint_exit"

///|
fn file_exists(path : String) -> Bool {
  file_exists_raw(@utf8.encode(path)) == 1
}

///|
fn read_file(path : String) -> String? {
  if !file_exists(path) {
    return None
  }
  Some(@utf8.decode_lossy(read_file_raw(@utf8.encode(path))))
}

///|
fn read_stdin() -> String {
  @utf8.decode_lossy(read_stdin_raw())
}

///|
fn exit_process(code : Int) -> Unit {
  exit_raw(code)
}
