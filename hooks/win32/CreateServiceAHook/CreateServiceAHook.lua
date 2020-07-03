Hook {
  name = "CreateServiceAHook",
  target = "sechost!CreateServiceA",
  decl = [[
    SC_HANDLE CreateServiceA(
      SC_HANDLE hSCManager,
      LPCSTR    lpServiceName,
      LPCSTR    lpDisplayName,
      DWORD     dwDesiredAccess,
      DWORD     dwServiceType,
      DWORD     dwStartType,
      DWORD     dwErrorControl,
      LPCSTR    lpBinaryPathName,
      LPCSTR    lpLoadOrderGroup,
      LPDWORD   lpdwTagId,
      LPCSTR    lpDependencies,
      LPCSTR    lpServiceStartName,
      LPCSTR    lpPassword
    );
  ]]
}
