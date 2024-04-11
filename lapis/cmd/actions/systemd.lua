local default_environment
default_environment = require("lapis.cmd.util").default_environment
local parse_flags
parse_flags = require("lapis.cmd.util").parse_flags
local parsed_args = false
return {
  argparser = function()
    parsed_args = true
    local parser = require("argparse")("lapis systemd", "Manage systemd integration for lapis app")
    parser:command_target("command")
    do
      local _with_0 = parser:command("service", "Generate service file")
      _with_0:argument("environment", "Environment to generate service file for (overrides --environment)"):args("?")
      _with_0:mutex(_with_0:flag("--install", "Installs the service file to the system, requires sudo permission"), _with_0:flag("--print -p", "Print the service file to stdout instead of writing it"))
    end
    parser:add_help_command()
    return parser
  end,
  function(self, args, lapis_args)
    assert(parsed_args, "The version of Lapis you are using does not support this version of lapis-systemd. Please upgrade Lapis ≥ v1.14.0")
    local _exp_0 = args.command
    if "service" == _exp_0 then
      local environment = args.environment or lapis_args.environment
      local config = self:get_config(environment)
      local path = require("lapis.cmd.path").annotate()
      local render_service_file
      render_service_file = require("lapis.systemd.service").render_service_file
      local contents, file, dir = render_service_file(config)
      if args.print then
        return print(contents)
      else
        path.write_file(file, contents)
        if args.install then
          local src = path.shell_escape(tostring(dir) .. "/" .. tostring(file))
          local dest = path.shell_escape("/usr/lib/systemd/system/" .. tostring(file))
          path.exec("sudo cp '" .. tostring(src) .. "' '" .. tostring(dest) .. "'")
          return path.exec("sudo systemctl daemon-reload")
        end
      end
    else
      return error("Unhandled command: " .. tostring(args.command))
    end
  end
}
