Hook {
  name = "OpenServiceWHook",
  target = "sechost!OpenServiceW",
  decl = [[
    SC_HANDLE OpenServiceW(
      SC_HANDLE hSCManager,
      LPCWSTR   lpServiceName,
      DWORD     dwDesiredAccess
    );
  ]]
}
