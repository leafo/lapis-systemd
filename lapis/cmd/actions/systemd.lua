local default_environment
default_environment = require("lapis.cmd.util").default_environment
local parse_flags
parse_flags = require("lapis.cmd.util").parse_flags
return {
  name = "systemd",
  usage = "systemd service [environment] [--install]",
  help = "create systemd service files",
  function(...)
    local flags, args = parse_flags({
      ...
    })
    local command, environment
    command, environment = args[1], args[2]
    environment = environment or default_environment()
    assert(command == "service", "must specify `lapis systemd service` as command")
    local config = require("lapis.config").get(environment)
    local path = require("lapis.cmd.path").annotate()
    local render_service_file
    render_service_file = require("lapis.systemd.service").render_service_file
    local contents, file, dir = render_service_file(config)
    path.write_file(file, contents)
    if flags.install then
      local src = path.shell_escape(tostring(dir) .. "/" .. tostring(file))
      local dest = path.shell_escape("/usr/lib/systemd/system/" .. tostring(file))
      path.exec("sudo cp '" .. tostring(src) .. "' '" .. tostring(dest) .. "'")
      return path.exec("sudo systemctl daemon-reload")
    end
  end
}
