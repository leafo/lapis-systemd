local conf = require("lapis.config")
local ffi = require("ffi")
local socket = require("socket")
ffi.cdef([[int sd_journal_print(int priority, const char *format, ...);
int sd_journal_send(const char *format, ...);
]])
local lib = ffi.load("libsystemd-journal")
local log
log = function(msg, priority)
  if priority == nil then
    priority = 6
  end
  return lib.sd_journal_send("PRIORITY=" .. tostring(priority), "MESSAGE=" .. tostring(msg), config.site_name and "SITE=" .. tostring(config.site_name) or nil)
end
return {
  log = log
}
