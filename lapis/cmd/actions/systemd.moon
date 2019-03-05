import default_environment from require "lapis.cmd.util"
import parse_flags from require "lapis.cmd.util"

{
  name: "systemd"
  usage: "systemd service [environment] [--link]"
  help: "create systemd service files"

  (flags, command, environment) =>
    environment or= default_environment!

    assert command == "service", "must specify `lapis systemd service` as command"

    config = require("lapis.config").get environment
    path = require("lapis.cmd.path").annotate!

    import render_service_file from require "lapis.systemd.service"

    contents, file, dir = render_service_file config

    path.write_file file, contents

    if flags.link
      src = path.shell_escape "#{dir}/#{file}"

      path.exec "sudo systemctl link '#{src}'"
      path.exec "sudo systemctl daemon-reload"
}
