Hook {
  name = "NtQueryInformationProcess",
  target = "ntdll!NtQueryInformationProcess",
  decl = [[
    NTSTATUS NtQueryInformationProcess(
      IN HANDLE           ProcessHandle,
      IN PROCESSINFOCLASS ProcessInformationClass,
      OUT PVOID           ProcessInformation,
      IN ULONG            ProcessInformationLength,
      OUT PULONG          ReturnLength
    )
  ]],
  onEntry = function(context)
    Event("MyEvent")
  end,
  onExit = function(context)
    Event("MyEvent")
  end
}
