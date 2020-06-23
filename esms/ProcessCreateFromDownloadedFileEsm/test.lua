setfenv(1, require "sysapi-ns")
local fs = require "fs.fs"
local web = require "web.web"
local File = require "file.File"
local Process = require "process.Process"

local package = Package "ProcessCreateFromDownloadedFileEsm"

Case("DISABLED_FileMonitorProbe") {
  case = function()
    local tempDir = fs.getTempDirectory()
    local fileName1 = tempDir .. "DbgMsgSrc.exe"
    local fileName2 = tempDir .. "DbgMsgSrc2.exe"
    local fileName3 = tempDir .. "DbgMsgSrc3.exe"
    package:load()
    web.downloadFile("https://github.com/CobaltFusion/DebugViewPP/releases/download/v1.8.0.95/DbgMsgSrc.exe", fileName1)

    Process.run(fileName1)

    ffi.C.CopyFileA(fileName1, fileName2, false)
    ffi.C.CopyFileA(fileName2, fileName3, false)

    Process.run(fileName2)
    Process.run(fileName3)

    package:unload()
  end
}
