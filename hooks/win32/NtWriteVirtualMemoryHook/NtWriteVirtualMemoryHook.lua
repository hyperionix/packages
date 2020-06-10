Hook {
  name = "NtWriteVirtualMemoryHook",
  target = "ntdll!NtWriteVirtualMemory",
  decl = [[
    NTSTATUS
    NtWriteVirtualMemory(
      IN HANDLE   ProcessHandle,
      IN PVOID    BaseAddress,
      IN PVOID    Buffer,
      IN ULONG    NumberOfBytesToWrite,
      OUT PULONG  NumberOfBytesWritten);
  ]]
}
