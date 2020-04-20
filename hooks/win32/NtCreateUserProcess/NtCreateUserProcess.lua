Hook {
  name = "NtCreateUserProcess",
  target = "ntdll!NtCreateUserProcess",
  decl = [[
    NTSTATUS NtCreateUserProcess(
        _Out_ PHANDLE ProcessHandle,
        _Out_ PHANDLE ThreadHandle,
        _In_ ACCESS_MASK ProcessDesiredAccess,
        _In_ ACCESS_MASK ThreadDesiredAccess,
        _In_opt_ POBJECT_ATTRIBUTES ProcessObjectAttributes,
        _In_opt_ POBJECT_ATTRIBUTES ThreadObjectAttributes,
        _In_ ULONG ProcessFlags,
        _In_ ULONG ThreadFlags,
        _In_opt_ PRTL_USER_PROCESS_PARAMETERS ProcessParameters,
        _Inout_ PPS_CREATE_INFO CreateInfo,
        _In_opt_ PVOID AttributeList
        );
  ]]
}
