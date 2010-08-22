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
      @tftpd = TFTPD.new
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
          w.puts("copy tftp #{@tftpd.default_addr} #{hostname}_aaa-local-db.csv aaa-local-db")
        end
        r.expect("done.\n#{hostname}# ") do
          w.puts("exit")
        end
      end
    end

    # This method creates MAC address filter configuration backup
    # for each switch every day. Then keep them for a month.
    def sync_from_switch_to_serv(location)
      hostname = location.hostname
      ipv4_addr = location.ipv4_addr
      username = @config[classname][hostname][0]
      password = @config[classname][hostname][1]
      # create date directory if it does not exist.
      day = Time.now.strftime("%d")
      dst_dir = "#{@tftpd.path}/#{day}"
      FileUtils.mkdir_p(dst_dir) if !File.exists?(dst_dir)
      PTY.spawn("#{ssh_cmd} #{username}@#{ipv4_addr}") do |r, w|
        w.sync = true
        r.expect("#{username}@#{ipv4_addr}'s password: ") do
          w.puts(password)
        end
        r.expect("#{hostname}> ") do
          w.puts("enable")
        end
        r.expect("#{hostname}# ") do
          w.puts("copy aaa-local-db tftp #{@tftpd.default_addr} #{dst_dir}/#{hostname}_aaa-local-db.csv")
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
