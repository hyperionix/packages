Hook {
  name = "NtUnloadDriverHook",
  target = "ntdll!NtUnloadDriver",
  decl = [[
    NTSTATUS NtUnloadDriver(
      _In_ PUNICODE_STRING DriverServiceName
    );
  ]]
}
