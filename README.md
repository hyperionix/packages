# Hyperionix packages
The repository contains packages for Hyperionix (http://hyperionix.com/) - a platform for development and deployment of modular OS monitoring and behavior modification packages. 

Developer documentation can be found [here](https://docs.hyperionix.com/)

## Hook package
![](https://raw.githubusercontent.com/hyperionix/resources/master/images/hook.gif)

## Probe package
![](https://raw.githubusercontent.com/hyperionix/resources/master/images/probe.gif)

## Repository packages list
| Package | HMC Ready | Test |
|---------|:---------:|:----:|
| Hooks|
| NtAllocateVirtualMemory|Yes|No|
| NtCreateFile|Yes|No|
| NtCreateThread|Yes|No|
| NtCreateThreadEx|Yes|No|
| NtCreateUserProcess|Yes|No|
| NtOpenFile|Yes|No|
| NtQueryInformationProcess|No|No|
| NtReadFile|Yes|No|
| NtSetInformationFile|Yes|No|
| NtWriteFile|Yes|No|
| NtWriteVirtualMemory|Yes|No|
| RtlInitUnicodeString|Yes|No|
| Probes|
| File Opened For Write|Yes|Yes|
| Interprocess Memory Allocation|Yes|Yes|
| Interprocess Memory Write|Yes|Yes|
| Interprocess Thread Creation|Yes|Yes|
| Process Created|Yes|Yes|
| Raw Disk Opened For Write|Yes|Yes|
| Raw Disk Write Access|Yes|Yes|
| Scheduled Probes|
| Services List|Yes|Yes|

