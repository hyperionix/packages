Hook {
  name = "CloseServiceHandleHook",
  target = "sechost!CloseServiceHandle",
  decl = [[
    BOOL CloseServiceHandle(
      SC_HANDLE hSCObject
    );
  ]]
}
