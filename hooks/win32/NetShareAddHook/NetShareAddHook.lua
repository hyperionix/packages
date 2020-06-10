Hook {
  name = "NetShareAddHook",
  target = "srvcli!NetShareAdd",
  decl = [[
    NET_API_STATUS NetShareAdd(
      LMSTR   servername,
      DWORD   level,
      LPBYTE  buf,
      LPDWORD parm_err
    );
  ]]
}
