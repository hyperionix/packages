Hook {
  name = "NetUserChangePasswordHook",
  target = "samcli!NetUserChangePassword",
  decl = [[
    NET_API_STATUS NetUserChangePassword(
      LPCWSTR domainname,
      LPCWSTR username,
      LPCWSTR oldpassword,
      LPCWSTR newpassword
    );
  ]]
}
