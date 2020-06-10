Hook {
  name = "NetShareEnumHook",
  target = "srvcli!NetShareEnum",
  decl = [[
    NET_API_STATUS NetShareEnum(
      LMSTR   servername,
      DWORD   level,
      LPBYTE  *bufptr,
      DWORD   prefmaxlen,
      LPDWORD entriesread,
      LPDWORD totalentries,
      LPDWORD resume_handle
    );
  ]]
}
