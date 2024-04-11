
describe "lapis.systemd.service", ->
  it "renders a basic service file", ->
    import render_service_file from require "lapis.systemd.service"
    contents, fname = render_service_file {
      _name: "development"
      systemd: {
        name: "my site"
        env: false
        user: "cool"
        lapis_bin: "/user/bin/lapis"
        dir: "/opt/my-site"
      }
    }

    assert.same "my-site-development.service", fname
    assert.same [[
[Unit]
Description=my site development
After=network.target

[Service]
Type=simple
PIDFile=/opt/my-site/logs/nginx.pid
User=cool
WorkingDirectory=/opt/my-site
ExecStart=/user/bin/lapis server development
ExecReload=/user/bin/lapis build development

[Install]
WantedBy=multi-user.target
]], contents


  it "renders service file with env", ->
    import render_service_file from require "lapis.systemd.service"

    lpath = os.getenv "LUA_PATH"

    contents, fname = render_service_file {
      _name: "development"
      systemd: {
        name: "my site"
        user: "cool"
        lapis_bin: "/user/bin/lapis"
        dir: "/opt/my-site"
        env: {
          "LUA_PATH"
          DATABASE_URL: "postgres://localhost/mydb"
        }
      }
    }

    assert.same "[Unit]
Description=my site development
After=network.target

[Service]
Type=simple
PIDFile=/opt/my-site/logs/nginx.pid
User=cool
Environment='LUA_PATH=#{lpath}' 'DATABASE_URL=postgres://localhost/mydb'
WorkingDirectory=/opt/my-site
ExecStart=/user/bin/lapis server development
ExecReload=/user/bin/lapis build development

[Install]
WantedBy=multi-user.target
", contents

