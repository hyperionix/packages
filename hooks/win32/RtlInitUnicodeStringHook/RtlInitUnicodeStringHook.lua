Hook {
  name = "RtlInitUnicodeStringHook",
  target = "ntdll!RtlInitUnicodeString",
  decl = [[
    NTSYSAPI VOID RtlInitUnicodeString(
      PUNICODE_STRING         DestinationString,
      __drv_aliasesMem PCWSTR SourceString
    );
  ]]
}
