Hook {
  name = "StartServiceWHook",
  target = "sechost!StartServiceW",
  decl = [[
    BOOL StartServiceW(
      SC_HANDLE hService,
      DWORD     dwNumServiceArgs,
      LPCWSTR   *lpServiceArgVectors
    );
  ]]
}
