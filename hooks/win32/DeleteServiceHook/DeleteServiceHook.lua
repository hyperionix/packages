Hook {
  name = "DeleteServiceHook",
  target = "sechost!DeleteService",
  decl = [[
    BOOL DeleteService(
      SC_HANDLE hService
    );
  ]]
}
