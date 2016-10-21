import default_environment from require "lapis.cmd.util"
import parse_flags from require "lapis.cmd.util"

{
  name: "systemd"
  usage: "systemd service [environment] [--install]"
  help: "create systemd service files"

  (...) =>
    flags, args = parse_flags { ... }
    { command, environment } = args

    environment or= default_environment!

    assert command == "service", "must specify `lapis systemd service` as command"

    config = require("lapis.config").get environment
    path = require("lapis.cmd.path").annotate!

    import render_service_file from require "lapis.systemd.service"

    contents, file, dir = render_service_file config

    path.write_file file, contents

    if flags.install
      src = path.shell_escape "#{dir}/#{file}"
      dest = path.shell_escape "/usr/lib/systemd/system/#{file}"

      path.exec "sudo cp '#{src}' '#{dest}'"
      path.exec "sudo systemctl daemon-reload"
}
