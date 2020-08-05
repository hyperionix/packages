Hook {
  name = "NtLoadDriverHook",
  target = "ntdll!NtLoadDriver",
  decl = [[
    NTSTATUS NtLoadDriver(
      _In_ PUNICODE_STRING DriverServiceName
    );
  ]]
}
