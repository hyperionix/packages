Hook {
  name = "NetUserEnumHook",
  target = "samcli!NetUserEnum",
  decl = [[
    NET_API_STATUS NetUserEnum(
      LPCWSTR servername,
      DWORD   level,
      DWORD   filter,
      LPBYTE  *bufptr,
      DWORD   prefmaxlen,
      LPDWORD entriesread,
      LPDWORD totalentries,
      PDWORD  resume_handle
    );
  ]]
}
