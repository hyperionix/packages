# Hyperionix Packages Repository
Hyperionix community driven repository of open-source packages and tools

## Overview
Hyperionix is a platform for development and deployment of modular OS monitoring and behavior modification packages. Building on top of community driven repository of open-source packages, it can be used to easily build security, monitoring and endpoint management products. It allows you to focus your efforts on the business logic, while leaving all the tedious and costly implementation details to the Hyperionix platform. The modern security, monitoring and application management landscape is fast changing and no proprietary product can keep up with the cornucopia of requirements and ideas.
To get more information check https://hyperionix.com/

## Licensing
* Development will always be free.
* Deploying Hyperionix Endpoint Agents on 10 machines or less is free.
* All packages in this repository are free and open source.

## Packages List
| Package | HMC Ready | Test |
|---------|:---------:|:----:|
| **Hooks**|
| NtAllocateVirtualMemory|Yes|No|
| NtCreateFile|Yes|No|
| NtCreateThread|Yes|No|
| NtCreateThreadEx|Yes|No|
| NtCreateUserProcess|Yes|No|
| NtOpenFile|Yes|No|
| NtReadFile|Yes|No|
| NtSetInformationFile|Yes|No|
| NtWriteFile|Yes|No|
| NtWriteVirtualMemory|Yes|No|
| RtlInitUnicodeString|Yes|No|
| **Probes**|
| File Opened For Write|Yes|Yes|
| Interprocess Memory Allocation|Yes|Yes|
| Interprocess Memory Write|Yes|Yes|
| Interprocess Thread Creation|Yes|Yes|
| Process Created|Yes|Yes|
| Raw Disk Opened For Write|Yes|Yes|
| **Scheduled Probes**|
| Services List|Yes|Yes