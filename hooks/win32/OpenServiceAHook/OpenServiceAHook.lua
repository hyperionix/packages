Hook {
  name = "OpenServiceAHook",
  target = "sechost!OpenServiceA",
  decl = [[
    SC_HANDLE OpenServiceA(
      SC_HANDLE hSCManager,
      LPCSTR    lpServiceName,
      DWORD     dwDesiredAccess
    );
  ]]
}
