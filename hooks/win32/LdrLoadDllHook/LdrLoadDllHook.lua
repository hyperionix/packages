Hook {
  name = "LdrLoadDllHook",
  target = "ntdll!LdrLoadDll",
  decl = [[
    NTSTATUS LdrLoadDll(
      _In_opt_ ULONG       Flags,
      _In_opt_ PULONG      Reserved,
      _In_ PUNICODE_STRING ModuleFileName,
      _Out_ PHANDLE        ModuleHandle);
  ]]
}
