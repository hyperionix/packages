Hook {
  name = "StartServiceAHook",
  target = "sechost!StartServiceA",
  decl = [[
    BOOL StartServiceA(
      SC_HANDLE hService,
      DWORD     dwNumServiceArgs,
      LPCSTR    *lpServiceArgVectors
    );
  ]]
}
