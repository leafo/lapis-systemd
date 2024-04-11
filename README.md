# lapis-systemd

`lapis-systemd` is a Lapis extension that lets you create `systemd` service
files for your Lapis applications. It also provides a minimal module to work
with the systemd journal.

## Install

```
$ luarocks install lapis-systemd
```

## Usage


```bash
$ lapis systemd service --help
Usage: lapis systemd service [-h] [--install] [<environment>]

Generate service file

Arguments:
   environment           Environment to generate service file for (overrides --environment)

Options:
   -h, --help            Show this help message and exit.
   --install             Installs the service file to the system, requires sudo permission
```

## Creating service files

The `service` command generates service files based on the environment
configuration. From your shell:

```bash
$ lapis systemd service development
```

Will generate a file in the current directory, named after your app:
`some-app-development.service`

The contents might look like this:

```ini
[Unit]
Description=some-app development
After=network.target

[Service]
Type=simple
PIDFile=/home/leafo/code/sites/itch.io/logs/nginx.pid
Environment='PATH=/home/leafo/.luarocks/bin:/usr/bin' 'LUA_PATH=;;/home/leafo/.luarocks/share/lua/5.1/?.lua;/home/leafo/.luarocks/share/lua/5.1/?/init.lua' 'LUA_CPATH=;;/home/leafo/.luarocks/lib/lua/5.1/?.so'
WorkingDirectory=/home/leafo/code/sites/itch.io
ExecStart=/home/leafo/.luarocks/bin/lapis server development
ExecReload=/home/leafo/.luarocks/bin/lapis build development

[Install]
WantedBy=multi-user.target
```

By default, service command will copy certain environment variables from the
current shell and embed them directly into the service file. This ensures that
Lapis is run as if you had launched it directly from your shell. The following
environment variables are embedded by default:

- `PATH`
- `LUA_PATH`
- `LUA_CPATH`

Because of these hard-coded paths, it is not recommended to check the generated
service files into your repository. If you ever move the project or reconfigure
your system, you should regenerate the service file.

You can generate and install the service file to the system using the following
command:

```bash
$ lapis systemd service development --install
```

**Do not run this command with sudo, as it will invoke sudo for you when
copying the necessary file. Executing it with sudo could result in a service
file with incorrect environment variables embedded**

You can then start your service:

```bash
$ sudo systemctl start some-app-development
```

And view the logs for it:

```bash
$ sudo journal -u some-app-development
```

### Configuring service file

The service file is configured from the `systemd` block within your Lapis
configuration. This simplifies the generation of a service file based on the
environment using a single, consistent command.

### `user`

The `user` option specifies the user under which the service will run. This can
be particularly useful if you need the service to have specific permissions
that are associated with a certain user.

If the `user` option is not provided,  the service will not specify a user will
run under the default user of the system.

In the configuration example below, the service will run as the user "leafo".

```lua
-- config.lua
local config = require("lapis.config")

config("production", {
  systemd = {
    user = "leafo" -- service will run as user
  }
})
```

If `user` is set to `true`, the name of the current user will be used. Note
that the user is embedded into the service file at the time of its creation and
is not dynamically determined at runtime. The user is determined via `whoami`
at the time of the service file's generation.

### `env`

The `env` option allows you specify the environment variables for the service.
The value of `env` can either be a string, a table, or a boolean.

By default systemd service files have a minimal `PATH` and no other environment
variables set. Any environment variables that are needed by your application
should be assigned in the service file.

If `env` is not set, it will default to copying the environment variables
`"PATH", "LUA_PATH", "LUA_CPATH"`. To avoid this default behavior set `env` to
false to skip setting environment variables in the service file, or manually
specify the value:

If `env` is a table, it can contain two types of entries, each representing how
to set the environment variable:

- Array entries: These are treated as names of environment variables that
  should be copied from the current shell environment.
- Key-value pairs: These represent environment variables that should be set
  directly, with the key as the variable name and the value as the variable
  value.

(If `env` is a string, it is considered used as a single name of the environment variable to copy)

For example:

If you want to set the environment variable `PORT` to `8080` and copy the
environment variable `DATABASE_URL`, you could use the following configuration:

```lua
-- config.lua
local config = require("lapis.config")

config("production", {
  systemd = {
    env = {
      PORT = 8080,
      "DATABASE_URL"
    }
  }
})
```
### `name`

The `name` option allowed for manual control of the name of the systemd
service.

If not set, the name is auto-generated from the last part of the current
directory name. For example, `/home/user/my-app` would default to `my-app`.

### `dir`

The `dir` option sets the service's working directory. If not set, it defaults
to the directory at the service file's generation time using `pwd`.

### `lapis_bin`

The `lapis_bin` option sets the location of the Lapis executable. If not set,
it defaults to the location returned by the command `which lapis`.

## Writing to logs

You can access the systemd journal with the `lapis.systemd.journal` module:

```lua
journal = require("lapis.systemd.journal")
journal.log("hello world!", {priority = 5})
```

Note this will only work if the `journal` config option is set to a truthy value.

### Journal Configuration

The log method will be a no-op unless the `journal` config option is set to a
truthy value. This will allow you to conditionally write to the journal based
on the Lapis environment.

```lua
-- config.lua
local config = require("lapis.config")

config("production", {
  systemd = {
    journal = true
  }
})
```

## Reading logs

This will loop forever listening for new log messages.

```lua
local j = require("lapis.systemd.journal")

for entry in j.listen() do
  print("Got entry:")
  for k, v in pairs(entry) do
    print(""k k,v)
  end
end
```

