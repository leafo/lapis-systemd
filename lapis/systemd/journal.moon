-- usage:
-- journalctl -f SITE=site_name

ffi = require "ffi"

socket = require "socket"

ffi.cdef [[
  int sd_journal_print(int priority, const char *format, ...);
  int sd_journal_send(const char *format, ...);
]]

lib = ffi.load "systemd"

site_name = ->
  service = require "lapis.systemd.service"
  name = service.site_name!
  site_name = -> name
  name

log = (msg, opts) ->
  priority = opts and opts.priority or 6
  name = site_name!
  commands = { "MESSAGE=#{msg}", "PRIORITY=#{priority}", "SITE=#{name}" }
  lib.sd_journal_send unpack commands

{ :log }
