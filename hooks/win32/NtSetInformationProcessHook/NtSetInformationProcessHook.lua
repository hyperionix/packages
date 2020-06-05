Hook {
  name = "NtSetInformationProcessHook",
  target = "ntdll!NtSetInformationProcess",
  decl = [[ 
    NTSTATUS
    NtSetInformationProcess(
      HANDLE           ProcessHandle,
      PROCESSINFOCLASS ProcessInformationClass,
      PVOID            ProcessInformation,
      ULONG            ProcessInformationLength
    );
  ]]
}
