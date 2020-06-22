setfenv(1, require "sysapi-ns")
local fs = require "fs.fs"
local web = require "web.web"
local File = require "file.File"
local Process = require "process.Process"
local EventChannel = hp.EventChannel

local SendAllToSplunkEsm = Package "SendAllToSplunkEsm"
local SendAllToFileEsm = Package "SendAllToFileEsm"

Case("TestEsm") {
  case = function()
    SendAllToSplunkEsm:load()
    SendAllToFileEsm:load()

    Event("Event2")
    Event("Event1")
    Event("Event3")
    Event("Event3")

    SendAllToFileEsm:unload()
    SendAllToSplunkEsm:unload()
  end
}

Case("DISABLED_TestEsm") {
  case = function()
    local tempDir = fs.getTempDirectory()
    local fileName1 = tempDir .. "\\test1.exe"
    local fileName2 = tempDir .. "\\test2.exe"
    local fileName3 = tempDir .. "\\test3.exe"
    local fileName4 = tempDir .. "\\test4.exe"

    package:load()

    web.downloadFile("https://github.com/CobaltFusion/DebugViewPP/releases/download/v1.8.0.95/DbgMsgSrc.exe", fileName1)

    ffi.C.CopyFileA(fileName1, fileName2, false)
    ffi.C.CopyFileA(fileName2, fileName3, false)
    ffi.C.MoveFileA(fileName3, fileName4)

    Process.run(fileName1)
    Process.run(fileName4)

    -- ffi.C.MoveFileExA(fileName1, fileName3, MOVEFILE_REPLACE_EXISTING)
    -- ffi.C.MoveFileExA(fileName1, fileName3, MOVEFILE_REPLACE_EXISTING)

    -- f = File.create(fileName1 .. ":stream1", CREATE_ALWAYS)
    -- f:close()

    -- f = File.create(fileName1 .. ":Zone.Identifier", CREATE_ALWAYS)
    -- f:close()

    -- ffi.C.CopyFileA(fileName1, fileName2, false)
    -- ffi.C.MoveFileA(fileName1, fileName3)
    -- File.delete(fileName2)
    -- File.delete(fileName3)

    -- File.delete(fileName1)

    package:unload()
  end
}
