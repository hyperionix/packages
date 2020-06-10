Hook {
  name = "NtDeviceIoControlFileHook",
  target = "ntdll!NtDeviceIoControlFile",
  decl = [[
    __kernel_entry NTSTATUS NtDeviceIoControlFile(
      IN HANDLE            FileHandle,
      IN HANDLE            Event,
      IN PIO_APC_ROUTINE   ApcRoutine,
      IN PVOID             ApcContext,
      OUT PIO_STATUS_BLOCK IoStatusBlock,
      IN ULONG             IoControlCode,
      IN PVOID             InputBuffer,
      IN ULONG             InputBufferLength,
      OUT PVOID            OutputBuffer,
      IN ULONG             OutputBufferLength
    );
  ]]
}
