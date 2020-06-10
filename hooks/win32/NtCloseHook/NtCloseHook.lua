Hook {
  name = "NtCloseHook",
  target = "ntdll!NtClose",
  decl = [[
    NTSTATUS NtClose(
      HANDLE Handle
    );
  ]]
}
