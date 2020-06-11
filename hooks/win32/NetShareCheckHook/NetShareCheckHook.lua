Hook {
  name = "NetShareCheckHook",
  target = "srvcli!NetShareCheck",
  decl = [[
    NET_API_STATUS NetShareCheck(
      LMSTR   servername,
      LMSTR   device,
      LPDWORD type
    );
  ]]
}
