Hook {
  name = "NtDeleteValueKeyHook",
  target = "ntdll!NtDeleteValueKey",
  decl = [[
    NTSTATUS
    NtDeleteValueKey(
      HANDLE KeyHandle,
      PUNICODE_STRING ValueName
    );
  ]]
}
