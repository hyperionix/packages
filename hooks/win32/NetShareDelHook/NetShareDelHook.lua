Hook {
  name = "NetShareDelHook",
  target = "srvcli!NetShareDel",
  decl = [[
    NET_API_STATUS NetShareDel(
      LMSTR servername,
      LMSTR netname,
      DWORD reserved
    );
  ]]
}
