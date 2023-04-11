-- usage:
-- journalctl -f SITE=site_name

ffi = require "ffi"

socket = require "socket"

lapis_config = require "lapis.config"

ffi.cdef [[
  int sd_journal_print(int priority, const char *format, ...);
  int sd_journal_send(const char *format, ...);


  typedef struct sd_journal sd_journal;

  int sd_journal_open(sd_journal **ret, int flags);
  int sd_journal_close(sd_journal *j);

  int sd_journal_next(sd_journal *j);
  int sd_journal_previous(sd_journal *j);
  int sd_journal_seek_head(sd_journal *j);
  int sd_journal_seek_tail(sd_journal *j);

  int sd_journal_add_match(sd_journal *j, const void *data, size_t size);

  int sd_journal_get_data(sd_journal *j, const char *field, const void **data, size_t *length);
  int sd_journal_enumerate_data(sd_journal *j, const void **data, size_t *length);

  int sd_journal_wait(sd_journal *j, int64_t timeout_usec);

  enum {
    SD_JOURNAL_LOCAL_ONLY = 1,
    SD_JOURNAL_RUNTIME_ONLY = 2,
    SD_JOURNAL_SYSTEM = 4,
    SD_JOURNAL_CURRENT_USER = 8
  };
]]

lib = ffi.load "systemd"

site_name = ->
  service = require "lapis.systemd.service"
  name = service.site_name!
  site_name = -> name
  name

log = (msg, opts) ->
  config = lapis_config.get!
  return unless config.systemd and config.systemd.journal

  priority = opts and opts.priority or 6
  name = site_name!
  commands = { "MESSAGE=#{msg}", "PRIORITY=#{priority}", "SITE=#{name}" }
  lib.sd_journal_send unpack commands

class JournalReader
  new: (@config={}) =>

  make_listener: =>
    journal_ptr = ffi.new("sd_journal*[1]")

    name = site_name!

    flags = lib.SD_JOURNAL_LOCAL_ONLY

    ret = lib.sd_journal_open(journal_ptr, flags or 0)
    if ret < 0
      error "Error opening journal: #{tonumber ret}"

    journal = journal_ptr[0]

    ffi.gc journal, lib.sd_journal_close

    if name = site_name!
      match = "SITE=" .. name
      lib.sd_journal_add_match journal, match, #match

    if @config.filter_unit
      match = "_SYSTEMD_UNIT=" .. unit_name
      lib.sd_journal_add_match journal, match, #match

    -- seek to the end of the journal
    lib.sd_journal_seek_tail journal
    lib.sd_journal_previous journal

    coroutine.wrap ->
      while true
        r = lib.sd_journal_next(journal)
        if r < 0
          error "Error reading journal: #{tonumber r}"

        if r == 0
          -- sleep until next entry is available
          lib.sd_journal_wait(journal, -1) -- -1 for an indefinite wait
          continue

        entry = @read_entry journal
        coroutine.yield entry

  read_entry: (journal) =>
    entry = {}

    data_ptr = ffi.new "const void*[1]"
    length = ffi.new "size_t[1]"

    field = lib.sd_journal_enumerate_data(journal, data_ptr, length)
    while field > 0
      data = ffi.string data_ptr[0], length[0]
      key, value = data\match("^(.-)=(.*)$")

      if key and value
        entry[key] = value

      field = lib.sd_journal_enumerate_data(journal, data_ptr, length)

    entry

-- create a infinite iterator that will listen for incoming messages from the
-- journal
listen = (opts) ->
  JournalReader(opts)\make_listener!

{ :log, :listen }
