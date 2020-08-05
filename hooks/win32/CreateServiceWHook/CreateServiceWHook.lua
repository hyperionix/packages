Hook {
  name = "CreateServiceWHook",
  target = "sechost!CreateServiceW",
  decl = [[
    SC_HANDLE CreateServiceW(
      SC_HANDLE hSCManager,
      LPCWSTR   lpServiceName,
      LPCWSTR   lpDisplayName,
      DWORD     dwDesiredAccess,
      DWORD     dwServiceType,
      DWORD     dwStartType,
      DWORD     dwErrorControl,
      LPCWSTR   lpBinaryPathName,
      LPCWSTR   lpLoadOrderGroup,
      LPDWORD   lpdwTagId,
      LPCWSTR   lpDependencies,
      LPCWSTR   lpServiceStartName,
      LPCWSTR   lpPassword
    );
  ]]
}
