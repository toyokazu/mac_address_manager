require 'yaml'
require 'csv'
require 'ipaddr'

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

  def rinda_worker_cluster
    "#{RAILS_ROOT}/script/rinda_worker_cluster"
  end

  desc "init all"
  task :init_all => [:"tftpd:init", :"infoblox:init"]

  desc "start servers"
  task :start_servers => [:"tftpd:start", :"tuplespace:start", :"workers:start"]

  desc "stop servers"
  task :stop_servers => [:"workers:stop", :"tuplespace:stop", :"tftpd:stop"]

  desc "genearte initial data"
  task :init_data => :environment do
    begin
      diff_addrs = SyncWorker.diff_addrs
      if diff_addrs.any? {|addrs| !addrs.empty?}
        raise "Several MacAddress entries are not synchronized yet."
      end
      if SyncWorker.executing?
        raise "Data synchronization job is running now..."
      end

      admin = User.first(:conditions => {:name => 'admin'})
      users = User.all(:conditions => ["name IS NOT 'admin'"])
      # cse_hosts.csv from Google Docs
      # IPaddr, hostname, MACaddr, Comments, Supplemental
      # row[0], row[1],   row[2],  row[3],   row[4]
      CSV::Reader.parse(File.open(ENV["CSV_IN"] || "#{RAILS_ROOT}/db/cse_hosts.csv", "rb")) do |row|
        # skip invalid address entry.
        begin
          IPAddr.new(row[0])
        rescue => e
          next
        end
        # skip address owned by 'admin' user.
        #next if admin.networks.any? {|net| net.addr.include?(row[0])}
        # skip entries where hostname is nil.
        next if row[1].nil?
        # get owner
        owner = nil
        owner = users.find do |user|
          user.networks.any? {|net| net.addr.include?(row[0])}
        end
        next if owner.nil?
        # create MacAddress entry
        mac_addr = row[2].nil? ? nil : MacAddress.normalize_mac_addr(row[2])
        mac_address =
          MacAddress.first(:conditions => {:ipv4_addr => row[0], :hostname => row[1], :mac_addr => mac_addr}) ||
          MacAddress.create(:ipv4_addr => row[0], :hostname => row[1], :mac_addr => row[2], :description => row[3], :group => owner.default_group)
        mac_address.location_ids = owner.default_group.location_ids
        mac_address.save
      end

      # The entities initialized here are assumed to be registered to the
      # backend systems manually. So thus, a virtual synchronization process
      # recorded here.
      worker_record = SyncWorker.worker_record(true)
      worker_record.start_at = Time.now
      sleep(1)
      worker_record.end_at = Time.now
      worker_record.save
    rescue => e
      puts e.message
      puts e.backtrace
    end
  end

  namespace :tuplespace do
    desc "start rinda_ts"
    task :start do
      @start_tuplespace = "#{rinda_ts} --daemon start"
      puts @start_tuplespace
      system @start_tuplespace
    end

    desc "stop rinda_ts"
    task :stop do
      @stop_tuplespace = "#{rinda_ts} --daemon stop"
      puts @stop_tuplespace
      system @stop_tuplespace
    end
  end

  namespace :workers do
    desc "start workers"
    task :start do
      @start_workers = "#{rinda_worker_cluster} start"
      puts @start_workers
      system @start_workers
    end

    desc "stop workers"
    task :stop do
      @stop_workers = "#{rinda_worker_cluster} stop"
      puts @stop_workers
      system @stop_workers
    end
  end
end
