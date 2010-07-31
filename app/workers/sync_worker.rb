require 'csv'
require 'openssl'
class SyncWorker < Rinda::Worker
  class << self # Class Methods
  end

  def initialize(ts, options = {})
    super(ts, options)
  end

  def main_loop
    @infoblox_client = Rinda::Client.new('infoblox', :ts => @ts, :key => @key, :logger => @logger)
    @switch_client = Rinda::Client.new('switch', :ts => @ts, :key => @key, :logger => @logger)
    super()
  end

  def sync
    worker_record = Rinda::CronWorker.worker_record(self.class.to_s)
    # previous execution was finished normally
    @start_at = nil
    if !worker_record.nil? && worker_record.end_at > worker_record.start_at
      @start_at = worker_record.start_at
    end

    # At first generate Infoblox tasks

    # To reduce the number of rows processed, use worker_record timestamp.
    #
    # Newly created entries will not checked before submitting jobs to InfobloxWorker.
    # If it requests to create already registered entry, InfobloxWorker
    # (InfobloxManger.pm) just output errors and proceeds next entry, so thus no problems.
    created_addrs = MacAddress.created_after(@start_at).all
    # In update case, check if there are the versioned entries before submitting.
    updated_addrs = with_older_version?(MacAddress.updated_after(@start_at).all)
    # In delete case, there is no need to check (deleted entries must not be found here).
    deleted_addrs = MacAddress.deleted_after(@start_at).find_with_deleted(:all)

    # additional updates caused by alias_name update
    additional_addrs = []
    alias_name_updated_addrs(@start_at).each do |addr|
      if !created_addrs.include?(addr) && !updated_addrs.include?(addr) && !deleted_addrs.include?(addr)
        additional_addrs << addr
      end
    end

    tasks = []
    tasks = tasks + to_infoblox_task("create", created_addrs)
    tasks = tasks + to_infoblox_task("update", updated_addrs)
    tasks = tasks + to_infoblox_task("update", additional_addrs)
    tasks = tasks + to_infoblox_task("delete", deleted_addrs)

    # output tmp/infoblox/year-month-day-hour-minute-sec-usec.yml
    # those files should be removed by cron_worker (after a week seems to be good
    # for default?)
    task_file = "#{RAILS_ROOT}/tmp/infoblox/#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}-#{Time.now.usec}"
    File.open(task_file) do |f|
      YAML.dump(tasks, f)
    end

    # submit Infoblox task into TupleSpace
    @infoblox_client.write_request("sync", task_file)

    # generate aaa-local-db for all switches
    
    # output tmp/tftproot/hostname_aaa-local-db.csv
    # for mac address filtering DB, all updates are submitted to
    # all switches to simplify the implementation.
    locations = Location.all
    locations.each do |location|
      csv_file = "#{RAILS_ROOT}/tmp/tftproot/#{location.hostname}_aaa-local-db.csv"
      CSV::Writer.generate(csv_file, "\t") do |csv|
        location.mac_addresses.each do |mac_addr|
          csv << [mac_addr.mac_addr]
        end
      end
      # submit Switch task into TupleSpace
      @switch_client.write_request("sync", location)
    end
  end

  protected
  def with_older_version?(addrs)
    updated_addrs = []
    addrs.each do |addr|
      if addr.versions.count > 1
        updated_addrs << addr
      end
    end
    updated_addrs
  end

  def to_infoblox_task(mac_addrs, operation)
    mac_addrs.map do |addr|
      ["host_record",
        [operation,
          addr.hostname,
          addr.ipv4_addr,
          addr.ipv6_addr,
          addr.alias_names.map {|alias_name| alias_name.hostname},
          addr.comment
        ]
      ]
    end
  end

  def alias_name_updated_addrs(time)
    AliasName.changed_after(time)
  end
end
