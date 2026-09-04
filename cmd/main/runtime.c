#include <moonbit.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef _WIN32
#include <io.h>
#else
#include <unistd.h>
#endif

MOONBIT_FFI_EXPORT
int32_t moonhadolint_file_exists(moonbit_bytes_t path) {
  const char *file_path = (const char *)path;
#ifdef _WIN32
  return _access(file_path, 0) == 0 ? 1 : 0;
#else
  return access(file_path, F_OK) == 0 ? 1 : 0;
#endif
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t moonhadolint_read_file(moonbit_bytes_t path) {
  const char *file_path = (const char *)path;
  FILE *file = fopen(file_path, "rb");
  if (file == NULL) {
    return moonbit_make_bytes(0, 0);
  }
  if (fseek(file, 0, SEEK_END) != 0) {
    fclose(file);
    return moonbit_make_bytes(0, 0);
  }
  long size = ftell(file);
  if (size < 0) {
    fclose(file);
    return moonbit_make_bytes(0, 0);
  }
  rewind(file);
  moonbit_bytes_t bytes = moonbit_make_bytes((int32_t)size, 0);
  if (size == 0) {
    fclose(file);
    return bytes;
  }
  size_t read = fread(bytes, 1, (size_t)size, file);
  fclose(file);
  if (read != (size_t)size) {
    return moonbit_make_bytes(0, 0);
  }
  return bytes;
}

MOONBIT_FFI_EXPORT
void moonhadolint_exit(int32_t code) {
  exit(code);
}
