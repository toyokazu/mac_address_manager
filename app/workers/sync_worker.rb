require 'csv'
require 'openssl'
class SyncWorker < Rinda::Worker
  class << self # Class Methods
    def worker_record(force = false)
      Rinda::CronWorker.worker_record('SyncWorker', force)
    end

    def executing?
      worker_record = SyncWorker.worker_record
      (!worker_record.nil? && (worker_record.end_at.nil? || worker_record.end_at < worker_record.start_at))
    end

    def latest_finished_job_start_at
      worker_record = SyncWorker.worker_record
      # previous execution was finished normally
      start_at = nil
      # get latest finished SyncWorker job start time (start_at)
      if !worker_record.nil? && !worker_record.end_at.nil?
        if worker_record.end_at > worker_record.start_at
          start_at = worker_record.start_at
        else
          start_at = worker_record.versions.last.previous.start_at
        end
      end
      start_at
    end

    def diff_addrs
      start_at = SyncWorker.latest_finished_job_start_at

      # At first generate Infoblox tasks

      # To reduce the number of rows processed, use worker_record timestamp.
      #
      # Newly created entries will not checked before submitting jobs to InfobloxWorker.
      # If it requests to create already registered entry, InfobloxWorker
      # (InfobloxManger.pm) just output errors and proceeds next entry, so thus no problems.
      created_addrs = MacAddress.created_after(start_at).all
      # In update case, check if there are the versioned entries before submitting.
      updated_addrs = with_older_version?(MacAddress.updated_after(start_at).all)
      # In delete case, there is no need to check (deleted entries must not be found here).
      deleted_addrs = MacAddress.deleted_after(start_at).find_with_deleted(:all)

      # additional updates caused by alias_name update
      additional_addrs = []
      updated_alias_names(start_at).each do |alias_name|
        if !created_addrs.include?(alias_name.mac_address) && !updated_addrs.include?(alias_name.mac_address) && !deleted_addrs.include?(alias_name.mac_address)
          additional_addrs << alias_name.mac_address
        end
      end
      [created_addrs, updated_addrs, deleted_addrs, additional_addrs]
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

    def updated_alias_names(time)
      AliasName.changed_after(time)
    end
  end

  def initialize(ts, options = {})
    super(ts, options)
  end

  def main_loop
    @infoblox_client = Rinda::Client.new('infoblox', :ts => @ts, :key => @key, :logger => @logger)
    @switch_client = Rinda::Client.new('switch', :ts => @ts, :key => @key, :logger => @logger)
    super()
  end

  def sync(options = {})
    created_addrs, updated_addrs, deleted_addrs, additional_addrs = SyncWorker.diff_addrs

    diff_addrs = created_addrs + updated_addrs + deleted_addrs + additional_addrs

    # if there is no updates, just return.
    if diff_addrs.empty?
      logger.debug "No updates are found in SyncWorker#sync. Do nothing."
      return
    end

    tasks = []
    tasks = tasks + to_infoblox_task("create", created_addrs)
    tasks = tasks + to_infoblox_task("update", updated_addrs)
    tasks = tasks + to_infoblox_task("update", additional_addrs)
    tasks = tasks + to_infoblox_task("delete", deleted_addrs)

    # output tmp/infoblox/year-month-day-hour-minute-sec-usec.yml
    # those files should be removed by cron_worker (after a week seems to be good
    # for default?)
    path = "#{RAILS_ROOT}/tmp/infoblox"
    FileUtils.mkdir_p(path) if !File.exists?(path)
    task_file = "#{path}/#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}-#{Time.now.usec}"
    File.open(task_file, "wb") do |f|
      YAML.dump(tasks, f)
    end

    # submit Infoblox task into TupleSpace
    @infoblox_client.write_request("update", task_file)

    # generate aaa-local-db for all switches
    
    # output tmp/tftproot/hostname_aaa-local-db.csv
    # for mac address filtering DB, all updates are submitted to
    # all switches to simplify the implementation.
    locations = []
    diff_addrs.each do |diff_addr|
      locations = (locations + diff_addr.locations).uniq
    end
    locations.each do |location|
      csv_file = "#{RAILS_ROOT}/tmp/tftproot/#{location.hostname}_aaa-local-db.csv"
      CSV::Writer.generate(File.open(csv_file, "w"), "\t") do |csv|
        location.mac_addresses.each do |mac_addr|
          csv << [mac_addr.packed_mac_addr]
        end
      end
      # submit Switch task into TupleSpace
      @switch_client.write_request("update", location.attributes)
    end
  end

  protected
  def to_infoblox_task(operation, mac_addrs)
    mac_addrs.map do |addr|
      ["host_record",
        [operation,
          addr.hostname,
          addr.ipv4_addr,
          addr.ipv6_addr,
          addr.mac_addr,
          addr.dhcp,
          addr.alias_names.map {|alias_name| alias_name.hostname},
          addr.description
        ]
      ]
    end
  end
end
