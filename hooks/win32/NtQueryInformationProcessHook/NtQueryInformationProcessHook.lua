Hook {
  name = "NtQueryInformationProcessHook",
  target = "ntdll!NtQueryInformationProcess",
  decl = [[
    NTSTATUS NtQueryInformationProcess(
      IN HANDLE           ProcessHandle,
      IN PROCESSINFOCLASS ProcessInformationClass,
      OUT PVOID           ProcessInformation,
      IN ULONG            ProcessInformationLength,
      OUT PULONG          ReturnLength
    )
  ]]
}
