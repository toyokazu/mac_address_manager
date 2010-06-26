require 'yaml'

namespace :setup do
  def output_error(error, message)
    puts "Error occurred during #{message}."
    puts "#{error.class}: #{error.message}"
    puts error.backtrace
  end

  def rinda_ts
    "#{RAILS_ROOT}/script/rinda_ts"
  end

  def rinda_worker
    "#{RAILS_ROOT}/script/rinda_worker"
  end

  task :config => :environment do
    begin
      # @config = YAML.load_file("#{RAILS_ROOT}/config/setup.yml")
      @workers = YAML.load_file("#{RAILS_ROOT}/config/workers.yml")
    rescue => error
      output_error(error, "reading configuration file")
    end
  end

  desc "init all"
  task :init_all => [:"tftpd:init", :"infoblox:init"]

  desc "start servers"
  task :start_servers => [:"tftpd:start", :"tuplespace:start", :"cron_worker:start", :"workers:start"]

  desc "stop servers"
  task :stop_servers => [:"workers:stop", :"cron_worker:stop", :"tuplespace:stop", :"tftpd:stop"]

  namespace :tuplespace do
    desc "start rinda_ts"
    task :start => :config do
      @start_tuplespace = "#{rinda_ts} --daemon start"
      puts @start_tuplespace
      system @start_tuplespace
    end

    desc "stop rinda_ts"
    task :stop => :config do
      @stop_tuplespace = "#{rinda_ts} --daemon stop"
      puts @stop_tuplespace
      system @stop_tuplespace
    end
  end

  namespace :cron_worker do
    desc "start cron_worker"
    task :start => :config do
      @start_cron_worker = "#{rinda_worker} --worker=rinda/cron --daemon --log=cron_worker.log --pid=cron_worker.pid start"
      puts @start_cron_worker
      system @start_cron_worker
    end

    desc "stop cron_worker"
    task :stop => :config do
      @stop_cron_worker = "#{rinda_worker} --worker=rinda/cron --daemon --log=cron_worker.log --pid=cron_worker.pid stop"
      puts @stop_cron_worker
      system @stop_cron_worker
    end
  end

  namespace :workers do
    desc "start workers"
    task :start => :config do
      ["update", "sync", "infoblox", "switch"].each do |worker|
        @start_worker = "#{rinda_worker} --worker=#{worker} --daemon --log=#{worker}_worker.log --threads=#{@workers[worker]} --pid=#{worker}_worker.pid start"
        puts @start_worker
        system @start_worker
      end
    end

    desc "stop workers"
    task :stop => :config do
      ["update", "sync", "infoblox", "switch"].each do |worker|
        @stop_worker = "#{rinda_worker} --worker=#{worker} --daemon --log=#{worker}_worker.log --threads=#{@workers[worker]} --pid=#{worker}_worker.pid stop"
        puts @stop_worker
        system @stop_worker
      end
    end
  end
end
