require 'yaml'

namespace :tftpd do
  def output_error(error, message)
    puts "Error occurred during #{message}."
    puts "#{error.class}: #{error.message}"
    puts error.backtrace
  end

  task :config => :environment do
    begin
      @config = YAML.load_file("#{RAILS_ROOT}/config/tftpd.yml")
      @user = @config["user"] || `/usr/bin/env id -un`.strip
      @path = "#{RAILS_ROOT}/tmp/tftproot"
      @default_addr = @config["default_addr"]
    rescue => error
      output_error(error, "reading configuration file")
    end
  end

  desc "init tftpd"
  task :init => :config do
    begin
      Dir.mkdir(@path) if !File.exists?(@path)
    rescue => error
      output_error(error, "initialize tftpd environments")
    end
  end
  
  desc "start tftpd"
  task :start => :config do
    begin
      @start_tftpd = "/usr/bin/sudo /usr/bin/env tftpd -v -c -u #{@user} -l #{"-a #{@default_addr}" if !@default_addr.nil?} -s #{@path}"
#      if !@default_addr.nil?
#        @start_tftpd = "#{@start_tftpd} -a #{@default_addr}"
#      end
      puts @start_tftpd
      system @start_tftpd
    rescue => error
      output_error(error, "starting up tftpd server")
    end
  end

  desc "stop tftpd"
  task :stop => :config do
    begin
      @stop_tftpd = "/usr/bin/sudo /usr/bin/killall tftpd"
      puts @stop_tftpd
      system @stop_tftpd
    rescue => error
      output_error(error, "stopping tftpd server")
    end
  end
end
