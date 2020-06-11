Hook {
  name = "NetShareDelExHook",
  target = "srvcli!NetShareDelEx",
  decl = [[
    NET_API_STATUS NetShareDelEx(
      LMSTR  servername,
      DWORD  level,
      LPBYTE buf
    );
  ]]
}
