-- usage:
-- journalctl -f SITE=site_name

conf = require "lapis.config"

ffi = require "ffi"

socket = require "socket"

ffi.cdef[[
int sd_journal_print(int priority, const char *format, ...);
int sd_journal_send(const char *format, ...);
]]

lib = ffi.load "libsystemd-journal"

log = (msg, priority=6) ->
  lib.sd_journal_send "PRIORITY=#{priority}", "MESSAGE=#{msg}", config.site_name and "SITE=#{config.site_name}" or nil

{ :log }
