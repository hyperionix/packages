Hook {
  name = "CryptExportKeyHook",
  target = "cryptsp!CryptExportKey",
  decl = [[
    BOOL CryptExportKey(
      HCRYPTKEY hKey,
      HCRYPTKEY hExpKey,
      DWORD     dwBlobType,
      DWORD     dwFlags,
      BYTE      *pbData,
      DWORD     *pdwDataLen
    );
  ]]
}
