
package = "lapis-systemd"
version = "dev-1"

source = {
  url = "git://github.com/leafo/lapis-systemd.git"
}

description = {
  summary = "Integrate Lapis with systemd",
  license = "MIT",
  maintainer = "Leaf Corcoran <leafot@gmail.com>",
}

dependencies = {
  "lua == 5.1",
  "lapis",
  "inifile",
}

build = {
  type = "builtin",
  modules = {
    ["lapis.cmd.actions.systemd"] = "lapis/cmd/actions/systemd.lua",
    ["lapis.systemd.journal"] = "lapis/systemd/journal.lua",
    ["lapis.systemd.service"] = "lapis/systemd/service.lua",
  }
}
