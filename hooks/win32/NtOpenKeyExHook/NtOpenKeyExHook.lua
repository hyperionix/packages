Hook {
  name = "NtOpenKeyExHook",
  target = "ntdll!NtOpenKeyEx",
  decl = [[
    NTSTATUS
    NtOpenKeyEx(
      PHANDLE KeyHandle,
      ACCESS_MASK DesiredAccess,
      POBJECT_ATTRIBUTES ObjectAttributes,
      ULONG OpenOptions
    );
  ]]
}
