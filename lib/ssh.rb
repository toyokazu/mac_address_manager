require 'pty'
require 'expect'
module SSH
  class Base
    def self.get_instance(location)
      (eval location.hosttype).new
    end

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

    def sync_from_serv_to_switch(location)
      hostname = location.hostname
      ipv4_addr = location.ipv4_addr
      username = @config[classname][hostname][0]
      password = @config[classname][hostname][1]
      PTY.spawn("#{ssh_cmd} #{username}@#{ipv4_addr}") do |r, w|
        w.sync = true
        r.expect("#{username}@#{ipv4_addr}'s password: ") do
          w.puts(password)
        end
        r.expect("#{hostname}> ") do
          w.puts("enable")
        end
        r.expect("#{hostname}# ") do
          w.puts("copy tftp #{@tftpd_addr} #{hostname}_aaa-local-db.csv aaa-local-db")
        end
        r.expect("done.\n#{hostname}# ") do
          w.puts("exit")
        end
      end
    end

    def sync_from_switch_to_serv(location)
      hostname = location.hostname
      ipv4_addr = location.ipv4_addr
      username = @config[classname][hostname][0]
      password = @config[classname][hostname][1]
      PTY.spawn("#{ssh_cmd} #{username}@#{ipv4_addr}") do |r, w|
        w.sync = true
        r.expect("#{username}@#{ipv4_addr}'s password: ") do
          w.puts(password)
        end
        r.expect("#{hostname}> ") do
          w.puts("enable")
        end
        r.expect("#{hostname}# ") do
          w.puts("copy aaa-local-db tftp #{@tftpd_addr} #{hostname}_aaa-local-db.csv")
        end
        r.expect("done.\n#{hostname}# ") do
          w.puts("exit")
        end
      end
    end
  end

  class Infoblox < Base
  end
end
