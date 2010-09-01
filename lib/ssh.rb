require 'pty'
require 'expect'
module SSH
  class Base
    def self.get_instance(location)
      (eval location["hosttype"]).new(location)
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
    def initialize(location)
      super()
      @tftpd = TFTPD.new
      @location = location
    end

    def hosttype
      @location["hosttype"]
    end

    def hostname
      @location["hostname"]
    end

    def ipv4_addr
      @location["ipv4_addr"]
    end

    def sync_from_serv_to_switch
      username = @config[hosttype][hostname][0]
      password = @config[hosttype][hostname][1]
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
        r.expect("#{hostname}# ") do
          w.puts("exit")
        end
      end
    end

    # This method creates MAC address filter configuration backup
    # for each switch every day. Then keep them for a month.
    def sync_from_switch_to_serv
      username = @config[hosttype][hostname][0]
      password = @config[hosttype][hostname][1]
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
        r.expect("#{hostname}# ") do
          w.puts("exit")
        end
      end
    end
  end

  class Alaxala < Base
  end
end
