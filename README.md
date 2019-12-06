# Hyperionix
Hyperionix community driven repository of open-source probes and tools


## OVERVIEW
Hyperionix is a platform for development and deployment of modular OS monitoring and behavior modification probes (or plugins). Building on top of community driven repository of open-source probes, it can be used to easily build security, monitoring and endpoint management products. It allows you to focus your efforts on the business logic, while leaving all the tedious and costly implementation details to the Hyperionix platform. The modern security, monitoring and application management landscape is fast changing and no proprietary product can keep up with the cornucopia of requirements and ideas.
## LICENSING
* Development will always be free.
* Deploying Hyperionix Endpoint Agents on 10 machines or less is free.
* All Probes in this repository are free and open source.
## COMPONENTS
Hyperionix consist of the following components:
### Hyperionix Endpoint
* Creates secure, fault tolerant and high performance environment for deployment of Probes
* Communicates with the Hyperionix Portal, Probe Repository and Data Collection Services (e.g. Splunk)
* May work in standalone mode without the Portal
* Support for monitoring in user and kernel modes
* Full low level control of all user mode and kernel processes
### Hyperionix Probe SDK
* Helps development of Probes without publishing
### Hyperionix Portal
* Provides secure command and control center for managing agents and probes both individually and via defined groups
* Displays, tracks and searches agent alerts and metadata
* Full monitoring details go to 3d party logging service (e.g. Splunk)
