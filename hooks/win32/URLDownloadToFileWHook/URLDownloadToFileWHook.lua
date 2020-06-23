Hook {
  name = "URLDownloadToFileWHook",
  target = "urlmon!URLDownloadToFileW",
  decl = [[
    HRESULT URLDownloadToFileW(
      LPUNKNOWN  pCaller,
      LPCTSTR    szURL,
      LPCTSTR    szFileName,
      DWORD      dwReserved,
      PVOID      lpfnCB
    );
  ]]
}
