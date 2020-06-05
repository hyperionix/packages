Hook {
  name = "NtCreateKeyHook",
  target = "ntdll!NtCreateKey",
  decl = [[
    NTSTATUS
    NtCreateKey(
      PHANDLE KeyHandle,
      ACCESS_MASK DesiredAccess,
      POBJECT_ATTRIBUTES ObjectAttributes,
      ULONG TitleIndex,
      PUNICODE_STRING Class,
      ULONG CreateOptions,
      PULONG Disposition
    );
  ]]
}
