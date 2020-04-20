Hook {
  name = "NtCreateThread",
  target = "ntdll!NtCreateThread",
  decl = [[ 
    NTSTATUS
    NtCreateThread(
      OUT PHANDLE             ThreadHandle,
      IN ACCESS_MASK          DesiredAccess,
      IN POBJECT_ATTRIBUTES   ObjectAttributes,
      IN HANDLE               ProcessHandle,
      OUT PCLIENT_ID          ClientId,
      IN PVOID                ThreadContext,
      IN PINITIAL_TEB         InitialTeb,
      IN BOOLEAN              CreateSuspended );    
  ]]
}
