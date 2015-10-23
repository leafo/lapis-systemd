local default_environment
default_environment = require("lapis.cmd.util").default_environment
return {
  name = "systemd",
  usage = "systemd service [environment]",
  help = "create systemd service files",
  function(environment)
    if environment == nil then
      environment = default_environment()
    end
    local config = require("lapis.config").get(environment)
    local path = require("lapis.cmd.path").annotate()
    local render_service_file
    render_service_file = require("lapis.systemd.service").render_service_file
    local contents, file, dir = render_service_file(config)
    path.write_file(file, contents)
    local src = path.shell_escape(tostring(dir) .. "/" .. tostring(file))
    local dest = path.shell_escape("/usr/lib/systemd/system/" .. tostring(file))
    if path.exists(dest) then
      path.exec("sudo rm '" .. tostring(dest) .. "'")
    end
    path.exec("sudo ln -s '" .. tostring(src) .. "' '" .. tostring(dest) .. "'")
    return path.exec("sudo systemctl daemon-reload")
  end
}
