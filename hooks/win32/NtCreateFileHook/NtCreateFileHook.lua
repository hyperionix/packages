Hook {
  name = "NtCreateFileHook",
  target = "ntdll!NtCreateFile",
  decl = [[
    __kernel_entry NTSTATUS NtCreateFile(
      OUT PHANDLE           FileHandle,
      IN ACCESS_MASK        DesiredAccess,
      IN POBJECT_ATTRIBUTES ObjectAttributes,
      OUT PIO_STATUS_BLOCK  IoStatusBlock,
      IN PLARGE_INTEGER     AllocationSize,
      IN ULONG              FileAttributes,
      IN ULONG              ShareAccess,
      IN ULONG              CreateDisposition,
      IN ULONG              CreateOptions,
      IN PVOID              EaBuffer,
      IN ULONG              EaLength
    );
  ]]
}
