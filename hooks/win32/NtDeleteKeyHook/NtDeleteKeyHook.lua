Hook {
  name = "NtDeleteKeyHook",
  target = "ntdll!NtDeleteKey",
  decl = [[
    NTSTATUS
    NtDeleteKey(
      HANDLE KeyHandle
    );
  ]]
}
