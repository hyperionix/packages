Hook {
  name = "NtQuerySystemInformationHook",
  target = "ntdll!NtQuerySystemInformation",
  decl = [[
    NTSTATUS NtQuerySystemInformation(
      _In_ SYSTEM_INFORMATION_CLASS SystemInformationClass,
      _Out_ PVOID                   SystemInformation,
      _In_ ULONG                    SystemInformationLength,
      _Out_opt_ PULONG              ReturnLength
    );
  ]]
}
