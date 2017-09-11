local ffi = require("ffi")
local socket = require("socket")
local config = require("lapis.config")
ffi.cdef([[  int sd_journal_print(int priority, const char *format, ...);
  int sd_journal_send(const char *format, ...);
]])
local lib = ffi.load("systemd")
local site_name
site_name = function()
  local service = require("lapis.systemd.service")
  local name = service.site_name()
  site_name = function()
    return name
  end
  return name
end
local log
log = function(msg, opts)
  if not (config.systemd and config.systemd.journal) then
    return 
  end
  local priority = opts and opts.priority or 6
  local name = site_name()
  local commands = {
    "MESSAGE=" .. tostring(msg),
    "PRIORITY=" .. tostring(priority),
    "SITE=" .. tostring(name)
  }
  return lib.sd_journal_send(unpack(commands))
end
return {
  log = log
}
