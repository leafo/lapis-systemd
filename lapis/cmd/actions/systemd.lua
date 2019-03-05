local default_environment
default_environment = require("lapis.cmd.util").default_environment
local parse_flags
parse_flags = require("lapis.cmd.util").parse_flags
return {
  name = "systemd",
  usage = "systemd service [environment] [--link]",
  help = "create systemd service files",
  function(self, flags, command, environment)
    environment = environment or default_environment()
    assert(command == "service", "must specify `lapis systemd service` as command")
    local config = require("lapis.config").get(environment)
    local path = require("lapis.cmd.path").annotate()
    local render_service_file
    render_service_file = require("lapis.systemd.service").render_service_file
    local contents, file, dir = render_service_file(config)
    path.write_file(file, contents)
    if flags.link then
      local src = path.shell_escape(tostring(dir) .. "/" .. tostring(file))
      path.exec("sudo systemctl link '" .. tostring(src) .. "'")
      return path.exec("sudo systemctl daemon-reload")
    end
  end
}
