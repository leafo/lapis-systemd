import default_environment from require "lapis.cmd.util"
import parse_flags from require "lapis.cmd.util"

parsed_args = false

{
  argparser: ->
    parsed_args = true

    parser = require("argparse") "lapis systemd", "Manage systemd integration for lapis app"
    parser\command_target "command"

    with parser\command "service", "Generate service file"
      \argument("environment", "Environment to generate service file for (overrides --environment)")\args("?")
      \mutex(
        \flag "--install", "Installs the service file to the system, requires sudo permission"
        \flag "--print -p", "Print the service file to stdout instead of writing it"
      )

    parser\add_help_command!

    parser

  (args, lapis_args) =>
    assert parsed_args,
      "The version of Lapis you are using does not support this version of lapis-systemd. Please upgrade Lapis ≥ v1.14.0"

    switch args.command
      when "service"
        environment = args.environment or lapis_args.environment

        config = @get_config environment

        path = require("lapis.cmd.path").annotate!

        import render_service_file from require "lapis.systemd.service"

        contents, file, dir = render_service_file config

        if args.print
          print contents
        else
          path.write_file file, contents

          if args.install
            src = path.shell_escape "#{dir}/#{file}"
            dest = path.shell_escape "/usr/lib/systemd/system/#{file}"

            path.exec "sudo cp '#{src}' '#{dest}'"
            path.exec "sudo systemctl daemon-reload"
      else
        error "Unhandled command: #{args.command}"
}
