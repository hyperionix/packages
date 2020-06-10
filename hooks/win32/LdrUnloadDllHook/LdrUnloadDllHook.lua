Hook {
  name = "LdrUnloadDllHook",
  target = "ntdll!LdrUnloadDll",
  decl = [[
    NTSTATUS LdrUnloadDll(
      _In_ HANDLE ModuleHandle);
  ]]
}
