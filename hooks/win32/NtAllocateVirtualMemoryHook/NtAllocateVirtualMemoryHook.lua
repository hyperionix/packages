Hook {
  name = "NtAllocateVirtualMemoryHook",
  target = "ntdll!NtAllocateVirtualMemory",
  decl = [[
    __kernel_entry NTSYSCALLAPI NTSTATUS NtAllocateVirtualMemory(
      HANDLE    ProcessHandle,
      PVOID     *BaseAddress,
      ULONG_PTR ZeroBits,
      PSIZE_T   RegionSize,
      ULONG     AllocationType,
      ULONG     Protect
    );
  ]]
}
