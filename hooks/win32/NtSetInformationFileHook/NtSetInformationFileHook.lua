Hook {
  name = "NtSetInformationFileHook",
  target = "ntdll!NtSetInformationFile",
  decl = [[
    __kernel_entry NTSYSCALLAPI NTSTATUS NtSetInformationFile(
      HANDLE                 FileHandle,
      PIO_STATUS_BLOCK       IoStatusBlock,
      PVOID                  FileInformation,
      ULONG                  Length,
      ULONG                  FileInformationClass
    );
  ]]
}
