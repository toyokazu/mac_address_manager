require 'pty'
require 'expect'
module SSH
  class Base
    def self.get_instance(location, logger = Logger.new(STDOUT))
      (eval location["hosttype"]).new(location, logger)
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
    class << self
      def aaa_local_db_path(tftpd_path, hostname)
        "#{tftpd_path}/#{hostname}_aaa-local-db.csv"
      end
    end

    def initialize(location, logger)
      super()
      @tftpd = TFTPD.new
      @location = location
      @logger = logger
    end

    def aaa_local_db_path
      Apresia.aaa_local_db_path(@tftpd.path, hostname)
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

    def sync_from_serv_to_switch_main
      if @config == false || @config[hosttype].nil? || @config[hosttype][hostname].nil?
        @logger.error "configuration for #{hostname} is not defined in ssh.yml"
        raise ArgumentError
      end
      username = @config[hosttype][hostname][0]
      password = @config[hosttype][hostname][1]
      PTY.spawn("#{ssh_cmd} #{username}@#{ipv4_addr}") do |r, w|
        # for debug
        $expect_verbose = true
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
        r.read if !r.eof?
      end
      true
    end

    def sync_from_serv_to_switch
      result = false
      until result
        begin
          result = sync_from_serv_to_switch_main
        rescue PTY::ChildExited, Errno::EIO => error
          @logger.error "#{error.class}: #{error.message}"
          @logger.error error.backtrace
          sleep 1
        rescue => error
          raise error
        end
      end
    end

    # This method creates MAC address filter configuration backup
    # for each switch every day. Then keep them for a month.
    def sync_from_switch_to_serv_main
      if @config == false || @config[hosttype].nil? || @config[hosttype][hostname].nil?
        @logger.error "configuration for #{hostname} is not defined in ssh.yml"
        raise ArgumentError
      end
      username = @config[hosttype][hostname][0]
      password = @config[hosttype][hostname][1]
      # create date directory if it does not exist.
      day = Time.now.strftime("%d")
      # FIXME
      # tftpd can not handle directory
      # currently add 'day' to filename
      dst_dir = "#{@tftpd.path}/#{day}"
      FileUtils.mkdir_p(dst_dir) if !File.exists?(dst_dir)
      PTY.spawn("#{ssh_cmd} #{username}@#{ipv4_addr}") do |r, w|
        # for debug
        $expect_verbose = true
        w.sync = true
        r.expect("#{username}@#{ipv4_addr}'s password: ") do
          w.puts(password)
        end
        r.expect("#{hostname}> ") do
          w.puts("enable")
        end
        r.expect("#{hostname}# ") do
          w.puts("copy aaa-local-db tftp #{@tftpd.default_addr} #{day}/#{hostname}_aaa-local-db.csv")
        end
        r.expect("#{hostname}# ") do
          w.puts("exit")
        end
        r.read if !r.eof?
      end
      true
    end

    def sync_from_switch_to_serv
      result = false
      until result
        begin
          result = sync_from_switch_to_serv_main
        rescue PTY::ChildExited, Errno::EIO => error
          @logger.error "#{error.class}: #{error.message}"
          @logger.error error.backtrace
          sleep 1
        rescue => error
          raise error
        end
      end
    end
  end

  class Alaxala < Base
  end
end
