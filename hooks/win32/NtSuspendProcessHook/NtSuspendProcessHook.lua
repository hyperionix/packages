Hook {
  name = "NtSuspendProcessHook",
  target = "ntdll!NtSuspendProcess",
  decl = [[ 
    NTSTATUS
    NtSuspendProcess(
      HANDLE ProcessHandle
    );
  ]]
}
