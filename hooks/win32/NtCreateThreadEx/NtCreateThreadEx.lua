Hook {
  name = "NtCreateThreadEx",
  target = "ntdll!NtCreateThreadEx",
  decl = [[
    NTSTATUS
    NtCreateThreadEx(
        _Out_ PHANDLE ThreadHandle,
        _In_ ACCESS_MASK DesiredAccess,
        _In_opt_ POBJECT_ATTRIBUTES ObjectAttributes,
        _In_ HANDLE ProcessHandle,
        _In_ PVOID StartRoutine, // PUSER_THREAD_START_ROUTINE
        _In_opt_ PVOID Argument,
        _In_ ULONG CreateFlags, // THREAD_CREATE_FLAGS_*
        _In_ SIZE_T ZeroBits,
        _In_ SIZE_T StackSize,
        _In_ SIZE_T MaximumStackSize,
        _In_opt_ PVOID AttributeList
        );
  ]]
}
