local ffi = require("ffi")
local socket = require("socket")
local lapis_config = require("lapis.config")
ffi.cdef([[  int sd_journal_print(int priority, const char *format, ...);
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
  local config = lapis_config.get()
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
local JournalReader
do
  local _class_0
  local _base_0 = {
    make_listener = function(self)
      local journal_ptr = ffi.new("sd_journal*[1]")
      local name = site_name()
      local flags = lib.SD_JOURNAL_LOCAL_ONLY
      local ret = lib.sd_journal_open(journal_ptr, flags or 0)
      if ret < 0 then
        error("Error opening journal: " .. tostring(tonumber(ret)))
      end
      local journal = journal_ptr[0]
      ffi.gc(journal, lib.sd_journal_close)
      do
        name = site_name()
        if name then
          local match = "SITE=" .. name
          lib.sd_journal_add_match(journal, match, #match)
        end
      end
      do
        local unit_name = self.config.filter_unit
        if unit_name then
          local match = "_SYSTEMD_UNIT=" .. unit_name
          lib.sd_journal_add_match(journal, match, #match)
        end
      end
      lib.sd_journal_seek_tail(journal)
      lib.sd_journal_previous(journal)
      return coroutine.wrap(function()
        while true do
          local _continue_0 = false
          repeat
            local r = lib.sd_journal_next(journal)
            if r < 0 then
              error("Error reading journal: " .. tostring(tonumber(r)))
            end
            if r == 0 then
              lib.sd_journal_wait(journal, -1)
              _continue_0 = true
              break
            end
            local entry = self:read_entry(journal)
            coroutine.yield(entry)
            _continue_0 = true
          until true
          if not _continue_0 then
            break
          end
        end
      end)
    end,
    read_entry = function(self, journal)
      local entry = { }
      local data_ptr = ffi.new("const void*[1]")
      local length = ffi.new("size_t[1]")
      local field = lib.sd_journal_enumerate_data(journal, data_ptr, length)
      while field > 0 do
        local data = ffi.string(data_ptr[0], length[0])
        local key, value = data:match("^(.-)=(.*)$")
        if key and value then
          entry[key] = value
        end
        field = lib.sd_journal_enumerate_data(journal, data_ptr, length)
      end
      return entry
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, config)
      if config == nil then
        config = { }
      end
      self.config = config
    end,
    __base = _base_0,
    __name = "JournalReader"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  JournalReader = _class_0
end
local listen
listen = function(opts)
  return JournalReader(opts):make_listener()
end
return {
  log = log,
  listen = listen
}
