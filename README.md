# lapis-systemd

`lapis-systemd` is a lapis extension that lets you create `systemd` service
files for your websites and log to the systemd journal easily.

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

You can use the new `service` command to generate service files for different
environments. From your shell:

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

The service generation command will copy certain environment variables from the
current shell and embed them directly into the service file. This ensures that
the running service will have the same visibility as the shell from which you
are running the command. The following environment variables are embedded:

- `PATH`
- `LUA_PATH`
- `LUA_CPATH`

Because of these hard-coded paths, it is not recommended to check the generated
service files into your repository. If you ever move the project or reconfigure
your system, you should regenerate the service file.

You can generate and install the service file to the system using the following
command: **(Do not run this command with sudo, as it will invoke sudo for you
when copying the necessary file. Executing it with sudo could result in a
service file with incorrect environment variables embedded)**

```bash
$ lapis systemd service development --install
```

You can then start your service:

```bash
$ sudo systemctl start some-app-development
```

And view the logs for it:

```bash
$ sudo journal -u some-app-development
```

### Configuring service file

The service file is configured from the `systemd` block within your Lapis configuration. This simplifies the generation of a service file based on the environment using a single, consistent command.

```lua
-- config.lua
local config = require("lapis.config")

config("production", {
  systemd = {
    user = "leafo" -- service will run as user
  }
})
```

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



