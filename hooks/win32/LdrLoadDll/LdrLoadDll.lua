Hook {
  name = "LdrLoadDll",
  target = "ntdll!LdrLoadDll",
  decl = [[
    NTSTATUS LdrLoadDll(
      _In_opt_ PWCHAR      PathToFile,
      _In_opt_ ULONG       Flags,
      _In_ PUNICODE_STRING ModuleFileName,
      _Out_ PHANDLE        ModuleHandle);
  ]]
}
