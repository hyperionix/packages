Hook {
  name = "CryptImportKey",
  target = "cryptsp!CryptImportKey",
  decl = [[
    BOOL CryptImportKey(
      HCRYPTPROV hProv,
      const BYTE *pbData,
      DWORD      dwDataLen,
      HCRYPTKEY  hPubKey,
      DWORD      dwFlags,
      HCRYPTKEY  *phKey
    );    
  ]]
}
