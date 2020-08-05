Hook {
  name = "ControlServiceExWHook",
  target = "sechost!ControlServiceExW",
  decl = [[
    BOOL ControlServiceExW(
      SC_HANDLE hService,
      DWORD     dwControl,
      DWORD     dwInfoLevel,
      PVOID     pControlParams
    );
  ]]
}
