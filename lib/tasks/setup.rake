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
  task :start_servers => [:"tftpd:start", :"tuplespace:start", :"workers:start"]

  desc "stop servers"
  task :stop_servers => [:"workers:stop", :"tuplespace:stop", :"tftpd:stop"]

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

  namespace :workers do
    desc "start workers"
    task :start => :config do
      @start_workers = "#{rinda_worker_cluster} start"
      puts @start_workers
      system @start_workers
    end

    desc "stop workers"
    task :stop => :config do
      @stop_workers = "#{rinda_worker_cluster} stop"
      puts @stop_workers
      system @stop_workers
    end
  end
end
