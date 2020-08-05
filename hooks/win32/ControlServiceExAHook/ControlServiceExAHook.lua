Hook {
  name = "ControlServiceExAHook",
  target = "sechost!ControlServiceExA",
  decl = [[
    BOOL ControlServiceExA(
      SC_HANDLE hService,
      DWORD     dwControl,
      DWORD     dwInfoLevel,
      PVOID     pControlParams
    );
  ]]
}
