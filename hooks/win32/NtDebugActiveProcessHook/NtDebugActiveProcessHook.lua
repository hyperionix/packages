Hook {
  name = "NtDebugActiveProcessHook",
  target = "ntdll!NtDebugActiveProcess",
  decl = [[ 
    NTSTATUS
    NtDebugActiveProcess(
      HANDLE ProcessHandle,
      HANDLE DebugObjectHandle
    );
  ]]
}
