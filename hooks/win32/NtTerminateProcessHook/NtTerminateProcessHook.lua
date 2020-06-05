Hook {
  name = "NtTerminateProcessHook",
  target = "ntdll!NtTerminateProcess",
  decl = [[ 
    NTSTATUS
    NtTerminateProcess(
      HANDLE ProcessHandle,
      NTSTATUS ExitStatus
    );
  ]]
}
