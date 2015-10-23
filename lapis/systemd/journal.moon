-- usage:
-- journalctl -f SITE=site_name

ffi = require "ffi"

socket = require "socket"

ffi.cdef [[
  int sd_journal_print(int priority, const char *format, ...);
  int sd_journal_send(const char *format, ...);
]]

lib = ffi.load "libsystemd-journal"

site_name = ->
  service = require "lapis.systemd.service"
  name = service.site_name!
  site_name = -> name
  name

log = (msg, priority=6) ->
  lib.sd_journal_send "PRIORITY=#{priority}", "MESSAGE=#{msg}", config.site_name and "SITE=#{site_name!}" or nil

{ :log }
