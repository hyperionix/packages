Hook {
  name = "NtOpenKeyHook",
  target = "ntdll!NtOpenKey",
  decl = [[
    NTSTATUS
    NtOpenKey(
      PHANDLE KeyHandle,
      ACCESS_MASK DesiredAccess,
      POBJECT_ATTRIBUTES ObjectAttributes
    );
  ]]
}
