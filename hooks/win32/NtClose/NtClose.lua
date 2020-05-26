Hook {
  name = "NtClose",
  target = "ntdll!NtClose",
  decl = [[
    NTSTATUS NtClose(
      HANDLE Handle
    );
  ]]
}
