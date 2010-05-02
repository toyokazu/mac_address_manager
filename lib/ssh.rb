require 'pty'
require 'expect'
module SSH
  class Base
    def initialize
      @config = YAML.load_file("#{RAILS_ROOT}/config/ssh.yml")
    end

    def classname
      self.class.to_s
    end

    def ssh_cmd
      "/usr/bin/env ssh"
    end
  end

  class Apresia < Base
    def initialize
      super
      @tftpd_config = YAML.load_file("#{RAILS_ROOT}/config/tftpd.yml")
      @tftpd_addr = @tftpd_config["default_addr"]
    end

    def upload_mac_list(location)
      hostname = location.hostname
      ipv4_addr = location.ipv4_addr
      username = @config[classname][hostname][0]
      password = @config[classname][hostname][1]
      PTY.spawn("#{ssh_cmd} #{username}@#{ipv4_addr}") do |r, w|
        w.sync = true
        r.expect("#{username}@#{ipv4_addr}'s password: ")
        w.puts(password)
        r.expect("#{hostname}> ")
        w.puts("enable")
        r.expect("#{hostname}# ")
        w.puts("copy tftp #{@tftpd_addr} #{hostname}_aaa-local-db.csv aaa-local-db")
        r.expect("done.\n#{hostname}# ")
        w.puts("exit")
      end
    end

    def download_mac_list(location)
      hostname = location.hostname
      ipv4_addr = location.ipv4_addr
      username = @config[classname][hostname][0]
      password = @config[classname][hostname][1]
      PTY.spawn("#{ssh_cmd} #{username}@#{ipv4_addr}") do |r, w|
        w.sync = true
        r.expect("#{username}@#{ipv4_addr}'s password: ")
        w.puts(password)
        r.expect("#{hostname}> ")
        w.puts("enable")
        r.expect("#{hostname}# ")
        w.puts("copy aaa-local-db tftp #{@tftpd_addr} #{hostname}_aaa-local-db.csv")
        r.expect("done.\n#{hostname}# ")
        w.puts("exit")
      end
    end
  end

  class Infoblox < Base
  end
end
