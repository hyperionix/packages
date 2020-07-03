Hook {
  name = "EnumServicesStatusAHook",
  target = "advapi32!EnumServicesStatusA",
  decl = [[
    BOOL EnumServicesStatusA(
      SC_HANDLE              hSCManager,
      DWORD                  dwServiceType,
      DWORD                  dwServiceState,
      LPENUM_SERVICE_STATUSA lpServices,
      DWORD                  cbBufSize,
      LPDWORD                pcbBytesNeeded,
      LPDWORD                lpServicesReturned,
      LPDWORD                lpResumeHandle
    );
  ]]
}
