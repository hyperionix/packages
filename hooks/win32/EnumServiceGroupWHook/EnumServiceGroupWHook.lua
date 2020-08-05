Hook {
  name = "EnumServiceGroupWHook",
  target = "advapi32!EnumServiceGroupW",
  decl = [[
    BOOL EnumServiceGroupW(
      SC_HANDLE              hSCManager,
      DWORD                  dwServiceType,
      DWORD                  dwServiceState,
      LPENUM_SERVICE_STATUSW lpServices,
      DWORD                  cbBufSize,
      LPDWORD                pcbBytesNeeded,
      LPDWORD                lpServicesReturned,
      LPDWORD                lpResumeHandle,
      LPCWSTR                lpGroup
    );
  ]]
}
