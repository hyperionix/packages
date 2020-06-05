Hook {
  name = "NtSetValueKeyHook",
  target = "ntdll!NtSetValueKey",
  decl = [[
    NTSTATUS
    NtSetValueKey(
      HANDLE KeyHandle,
      PUNICODE_STRING ValueName,
      ULONG TitleIndex,
      ULONG Type,
      PVOID Data,
      ULONG DataSize
    );
  ]]
}
