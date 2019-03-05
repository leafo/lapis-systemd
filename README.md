# lapis-systemd

`lapis-systemd` is a lapis extension that lets you create `systemd` service
files for your websites and log to the systemd journal easily.

## Install

```
$ luarocks install lapis-systemd
```

## Creating service files

You can use the new `systemd` command to generate service files for different
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
Environment='LUA_PATH=;;/home/leafo/.luarocks/share/lua/5.1/?.lua;/home/leafo/.luarocks/share/lua/5.1/?/init.lua' 'LUA_CPATH=;;/home/leafo/.luarocks/lib/lua/5.1/?.so'
WorkingDirectory=/home/leafo/code/sites/itch.io
ExecStart=/home/leafo/.luarocks/bin/lapis server development
ExecReload=/home/leafo/.luarocks/bin/lapis build development

[Install]
WantedBy=multi-user.target
```

Note that the path of your project is hard-coded into the service, along with
the path of the `lapis` binary and any Lua environment variables. If you ever
move the project around or reconfigure your system you should regenerate the
service file.

Since these paths are specific to a machine, it's not recommended to check the
service files into your respository.

You can generate and link the service file to the system with the following
command:

```bash
$ lapis systemd service development --link
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

The `systemd` entry in your lapis config can be used to control how the service file is generated:

```lua
-- config.lua
local config = require("lapis.config")

config("production", {
  systemd = {
    user = "leafo" -- service will run as user
  }
})
```

If you want to enable journal log writes (when using the `log` function in
`lapis.systemd.journal`) then you can set `journal = true` in systmed config
block:

```lua
-- config.lua
local config = require("lapis.config")

config("production", {
  systemd = {
    user = "leafo",
    journal = true
  }
})
```

## Writing to logs

You can access the systemd journal with the `lapis.systemd.journal` module:

```lua
journal = require("lapis.systemd.journal")
journal.log("hello world!", {priority = 5})
```
