namespace :tftpd do
  def output_error(error, message)
    puts "Error occurred during #{message}."
    puts "#{error.class}: #{error.message}"
    puts error.backtrace
  end

  task :config => :environment do
    begin
      @tftpd = TFTPD.new
      @tftpd.create_path 
    rescue => error
      output_error(error, "reading configuration file")
    end
  end

  desc "start tftpd"
  task :start => :config do
    begin
      @start_tftpd = "/usr/bin/sudo /usr/bin/env tftpd -v -c -u #{@tftpd.user} -l #{@tftpd.addr_option} -s #{@tftpd.path}"
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
