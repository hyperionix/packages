Hook {
  name = "NetUserAddHook",
  target = "samcli!NetUserAdd",
  decl = [[
    NET_API_STATUS NetUserAdd(
      LPCWSTR servername,
      DWORD   level,
      LPBYTE  buf,
      LPDWORD parm_err
    );
  ]]
}
