Hook {
  name = "NtOpenProcessHook",
  target = "ntdll!NtOpenProcess",
  decl = [[ 
    NTSTATUS NtOpenProcess(
      PHANDLE            ProcessHandle,
      ACCESS_MASK        DesiredAccess,
      POBJECT_ATTRIBUTES ObjectAttributes,
      PCLIENT_ID         ClientId
    );
  ]]
}
