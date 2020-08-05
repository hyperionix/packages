Hook {
  name = "ControlServiceHook",
  target = "sechost!ControlService",
  decl = [[
    BOOL ControlService(
      SC_HANDLE        hService,
      DWORD            dwControl,
      LPSERVICE_STATUS lpServiceStatus
    );
  ]]
}
