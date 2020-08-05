Hook {
  name = "EnumServicesStatusExAHook",
  target = "advapi32!EnumServicesStatusExA",
  decl = [[
    BOOL EnumServicesStatusExA(
      SC_HANDLE hSCManager,
      DWORD     InfoLevel,
      DWORD     dwServiceType,
      DWORD     dwServiceState,
      LPBYTE    lpServices,
      DWORD     cbBufSize,
      LPDWORD   pcbBytesNeeded,
      LPDWORD   lpServicesReturned,
      LPDWORD   lpResumeHandle,
      LPCSTR    pszGroupName
    );
  ]]
}
