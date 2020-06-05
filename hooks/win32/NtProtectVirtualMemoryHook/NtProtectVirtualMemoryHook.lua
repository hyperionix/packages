Hook {
  name = "NtProtectVirtualMemoryHook",
  target = "ntdll!NtProtectVirtualMemory",
  decl = [[
    NTSTATUS
    NtProtectVirtualMemory(
      HANDLE  ProcessHandle,
      PVOID   *BaseAddress,
      PULONG  NumberOfBytesToProtect,
      ULONG   NewAccessProtection,
      PULONG  OldAccessProtection
    );
  ]]
}
