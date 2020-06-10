Hook {
  name = "NetUserDelHook",
  target = "samcli!NetUserDel",
  decl = [[
    NET_API_STATUS NetUserDel(
      LPCWSTR servername,
      LPCWSTR username
    );
  ]]
}
