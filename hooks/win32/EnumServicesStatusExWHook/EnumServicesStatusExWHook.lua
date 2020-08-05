Hook {
  name = "EnumServicesStatusExWHook",
  target = "sechost!EnumServicesStatusExW",
  decl = [[
    BOOL EnumServicesStatusExW(
      SC_HANDLE hSCManager,
      DWORD     InfoLevel,
      DWORD     dwServiceType,
      DWORD     dwServiceState,
      LPBYTE    lpServices,
      DWORD     cbBufSize,
      LPDWORD   pcbBytesNeeded,
      LPDWORD   lpServicesReturned,
      LPDWORD   lpResumeHandle,
      LPCWSTR   pszGroupName
    );
  ]]
}
