Hook {
  name = "CryptGenKeyHook",
  target = "cryptsp!CryptGenKey",
  decl = [[
    BOOL CryptGenKey(
      HCRYPTPROV hProv,
      ALG_ID     Algid,
      DWORD      dwFlags,
      HCRYPTKEY  *phKey
    );
  ]]
}
