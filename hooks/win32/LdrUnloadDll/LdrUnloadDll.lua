Hook {
  name = "LdrUnloadDll",
  target = "ntdll!LdrUnloadDll",
  decl = [[
    NTSTATUS LdrUnloadDll(
      _In_ HANDLE ModuleHandle);
  ]]
}
