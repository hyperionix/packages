setfenv(1, require "sysapi-ns")
local fs = require "fs.fs"
local FilePath = require "file.Path"

local package = Package "Hide File"

local TEST_FILE = "C:\\Windows\\notepad.exe"

local function isFileDetected(sFullPath)
  local fullPath = FilePath.fromString(sFullPath)
  local fileName = fullPath.basename .. fullPath.ext

  for name in fs.dir(fullPath.drive .. fullPath.dir .. "*") do
    if name == fileName then
      return true
    end
  end

  return false
end

Case("mycase") {
  case = function()
    assert(isFileDetected(TEST_FILE) == true)
    package:load()
    assert(isFileDetected(TEST_FILE) == false)
    package:unload()
  end
}
