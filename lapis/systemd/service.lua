local DEFAULT_ENV_VARIABLES = {
  "PATH",
  "LUA_PATH",
  "LUA_CPATH"
}
local read
read = function(cmd)
  local f = io.popen(cmd)
  do
    local _with_0 = f:read("*a"):gsub("%s*$", "")
    f:close()
    return _with_0
  end
end
local site_name
site_name = function(config)
  if config == nil then
    config = require("lapis.config").get()
  end
  local slugify
  slugify = require("lapis.util").slugify
  local service_config = config.systemd or { }
  local name = service_config.name
  if not (name) then
    local dir = read("pwd")
    name = slugify(dir:match("[^/]*$") or "lapis-app")
  end
  return name
end
local prepare_ini
prepare_ini = function(tuples)
  local structure = { }
  local order = { }
  for _index_0 = 1, #tuples do
    local section = tuples[_index_0]
    local section_name = section[1]
    local _update_0 = section_name
    structure[_update_0] = structure[_update_0] or { }
    local items = math.max(unpack((function()
      local _accum_0 = { }
      local _len_0 = 1
      for i in pairs(section) do
        if type(i) == "number" then
          _accum_0[_len_0] = i
          _len_0 = _len_0 + 1
        end
      end
      return _accum_0
    end)()))
    local section_order
    do
      local _accum_0 = { }
      local _len_0 = 1
      for i = 2, items do
        local _continue_0 = false
        repeat
          if not (section[i]) then
            _continue_0 = true
            break
          end
          local key, value
          do
            local _obj_0 = section[i]
            key, value = _obj_0[1], _obj_0[2]
          end
          structure[section_name][key] = value
          local _value_0 = key
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
          _continue_0 = true
        until true
        if not _continue_0 then
          break
        end
      end
      section_order = _accum_0
    end
    section_order.name = section_name
    table.insert(order, section_order)
  end
  return setmetatable(structure, {
    __inifile = {
      sectionorder = order,
      comments = { }
    }
  })
end
local render_ini
render_ini = function(tuples)
  local tbl = prepare_ini(tuples)
  local inifile = require("inifile")
  return inifile.save("", tbl, "memory")
end
local render_service_file
render_service_file = function(config, args)
  local slugify
  slugify = require("lapis.util").slugify
  local path = require("lapis.cmd.path")
  local service_config = config.systemd or { }
  local dir = service_config.dir or read("pwd")
  local lapis = service_config.lapis_bin or read("which lapis")
  local name = site_name(config)
  assert(name, "failed to determine service name, please set name directly in config.systemd.name")
  local service_type
  if config.daemon == "on" then
    service_type = "forking"
  else
    service_type = "simple"
  end
  local file = slugify(tostring(name) .. " " .. tostring(config._name)) .. ".service"
  local contents = render_ini({
    {
      "Unit",
      {
        "Description",
        tostring(name) .. " " .. tostring(config._name)
      },
      {
        "After",
        "network.target"
      }
    },
    {
      "Service",
      {
        "Type",
        service_type
      },
      {
        "PIDFile",
        tostring(path.join(dir, "logs/nginx.pid"))
      },
      (function()
        if service_config.user == true then
          return {
            "User",
            read("whoami")
          }
        elseif service_config.user then
          return {
            "User",
            service_config.user
          }
        end
      end)(),
      (function()
        if not (service_config.env == false) then
          local env_names
          local _exp_0 = type(service_config.env)
          if "string" == _exp_0 then
            env_names = {
              service_config.env
            }
          elseif "table" == _exp_0 then
            env_names = service_config.env
          else
            env_names = DEFAULT_ENV_VARIABLES
          end
          local env_parts
          do
            local _accum_0 = { }
            local _len_0 = 1
            for env_k, env_v in pairs(env_names) do
              local env_name, env_value
              if type(env_k) == "number" then
                env_name, env_value = env_v, os.getenv(env_v)
              else
                env_name, env_value = env_k, env_v
              end
              local _value_0 = "'" .. tostring(env_name) .. "=" .. tostring(env_value) .. "'"
              _accum_0[_len_0] = _value_0
              _len_0 = _len_0 + 1
            end
            env_parts = _accum_0
          end
          return {
            "Environment",
            table.concat(env_parts, " ")
          }
        end
      end)(),
      {
        "WorkingDirectory",
        dir
      },
      {
        "ExecStart",
        tostring(lapis) .. " server " .. tostring(config._name)
      },
      {
        "ExecReload",
        tostring(lapis) .. " build " .. tostring(config._name)
      }
    },
    {
      "Install",
      {
        "WantedBy",
        "multi-user.target"
      }
    }
  })
  return contents, file, dir
end
return {
  render_ini = render_ini,
  render_service_file = render_service_file,
  site_name = site_name
}
