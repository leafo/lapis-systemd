
read = (cmd) ->
  f = io.popen cmd
  with f\read("*a")\gsub "%s*$", ""
    f\close!

prepare_ini = (tuples) ->
  structure = {}
  order = {}

  for section in *tuples
    section_name = section[1]
    structure[section_name] or={}

    section_order = for i=2,#section
      {key, value} = section[i]
      structure[section_name][key] = value
      key

    section_order.name = section_name
    table.insert order, section_order

  setmetatable structure, {
    __inifile: {
      sectionorder: order
      comments: {}
    }
  }

render_ini = (tuples) ->
  tbl = prepare_ini tuples
  inifile = require "inifile"
  inifile.save "", tbl, "memory"

render_service_file = (config) ->
  import slugify from require "lapis.util"
  path = require "lapis.cmd.path"

  service_config = config.systemd or {}

  dir = read "pwd"
  lapis = read "which lapis"

  site_name = service_config.name
  unless site_name
    site_name = slugify dir\match("[^/]*$") or "app"

  lua_path = os.getenv "LUA_PATH"
  lua_cpath = os.getenv "LUA_CPATH"

  service_type = if config.daemon == "on"
    "forking"
  else
    "simple"

  file = slugify("#{site_name} #{config._name}") .. ".service"

  contents = render_ini {
    {"Unit"
      {"Description", "#{site_name} #{config._name}"}
      {"After", "network.target"}
    }

    {"Service"
      {"Type", service_type}
      {"PIDFile", "#{path.join dir, "logs/nginx.pid"}"}
      {"Environment", "'LUA_PATH=#{lua_path}' 'LUA_CPATH=#{lua_cpath}'"}
      {"WorkingDirectory", dir}
      {"ExecStart", "#{lapis} server #{config._name}"}
      {"ExecReload", "#{lapis} build #{config._name}"}
    }

    {"Install"
      {"WantedBy", "multi-user.target"}
    }
  }

  contents, file, dir

{ :render_ini, :render_service_file }
