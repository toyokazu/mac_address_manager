require 'fileutils'
class SwitchWorker < Rinda::Worker
  class << self # Class Methods
    # FIXME
    # the following methods (aaa_local_db related) should be
    # moved to SSH::Apresia class. However, currently SSH::Apresia
    # is instantiated by location Hash by SwitchWorker (not Location
    # record). So thus, currently implemented here.
    def generate_aaa_local_db(tftpd__path, location, passwd)
      aaa_local_db_path = SSH::Apresia.aaa_local_db_path(tftpd_path, location.hostname)
      CSV.open(aaa_local_db_path, "wb") do |csv|
        location.mac_addresses.each do |mac_addr|
          csv << [mac_addr.packed_mac_addr, passwd, mac_addr.vlan_id]
        end
      end
    end

    def generate_aaa_local_db_from_cse_hosts(tftpd_path, cse_hosts_file, out_file, passwd, default_vlan, logger = Logger.new(STDOUT))
      cse_hosts = "#{tftpd_path}/#{cse_hosts_file}"
      aaa_local_db = "#{tftpd_path}/#{out_file}"
      File.open(aaa_local_db, "wb") do |f|
        CSV::Reader.parse(cse_hosts, "rb") do |row|
          if !row[2].nil?
            row[2] = MacAddress.normalize_mac_addr(row[2])
            if !MacAddress.validate_mac_addr(row[2])
              # comment line may be come here
              logger.warn "at SyncWorker#generate_aaa_local_db_from_cse_hosts"
              logger.warn "Invalid MAC address format."
              logger.warn "--"
              logger.warn "IP: #{row[0]}, "
              logger.warn "hostname: #{row[1]}"
              logger.warn "MAC: #{row[2]}"
              logger.warn "Comment: #{row[3]}"
              logger.warn "Supplemental: #{row[4]}"
              logger.warn "VLAN ID: #{row[5]}"
              logger.warn "--"
              next
            end
            f.puts "#{MacAddress.pack_mac_addr(row[2])},#{passwd},#{row[5] || default_vlan}"
          elsif !row[1].nil?
            logger.debug "at SyncWorker#generate_aaa_local_db_from_cse_hosts"
            logger.debug "MAC address is not specified."
            logger.debug "--"
            logger.debug "IP: #{row[0]}, "
            logger.debug "hostname: #{row[1]}"
            logger.debug "MAC: #{row[2]}"
            logger.debug "Comment: #{row[3]}"
            logger.debug "Supplemental: #{row[4]}"
            logger.debug "VLAN ID: #{row[5]}"
            logger.debug "--"
          end
        end
      end
    end

    def replace_aaa_local_db(tftpd_path, prev_file, new_file, logger = Logger.new(STDOUT))
      prev_aaa_local_db = "#{tftpd_path}/#{prev_file}"
      new_aaa_local_db = "#{tftpd_path}/#{new_file}"
      prev_entries = []
      new_entries = []
      CSV.open(prev_aaa_local_db, "rb", "\t") do |prev_entry|
        prev_entries << prev_entry
      end
      prev_entries = prev_entries.sort
      CSV.open(new_aaa_local_db, "rb", "\t") do |new_entry|
        new_entries << new_entry
      end
      new_entries = new_entries.sort
      # nothing is changed in new_file
      if ((prev_entries <=> new_entries) == 0)
        logger.info "Nothins is changed in #{new_file}."
        logger.info "Do nothing."
        return false
      end
      FileUtils.copy(new_aaa_local_db, prev_aaa_local_db)
      true
    end

    def copy_aaa_local_db(tftpd_path, file, locations)
      locations.each do |location|
        aaa_local_db_path = SSH::Apresia.aaa_local_db_path(tftpd_path, location.hostname)
        FileUtils.copy(file, aaa_local_db_path)
      end
    end
  end

  # location is a Hash of the Location attributes (Location#attributes)
  def update(location)
    switch = SSH::Base.get_instance(location, logger)
    # backup before update
    logger.info "#{switch.class.to_s}: {target: #{switch.hostname}, operation: sync_from_switch_to_serv}"
    switch.sync_from_switch_to_serv
    # update
    logger.info "#{switch.class.to_s}: {target: #{switch.hostname}, operation: sync_from_serv_to_switch}"
    switch.sync_from_serv_to_switch
    logger.info "#{switch.class.to_s}: {target: #{switch.hostname}, operation: sync_from_serv_to_switch} finished"
  end

  # location is a Hash of the Location attributes (Location#attributes)
  def backup(location)
    switch = SSH::Base.get_instance(location, logger)
    logger.info "#{switch.class.to_s}: {target: #{switch.hostname}, operation: sync_from_switch_to_serv}"
    switch.sync_from_switch_to_serv
    logger.info "#{switch.class.to_s}: {target: #{switch.hostname}, operation: sync_from_switch_to_serv} finished"
  end

  def backup_all(options = {})
    locations = Location.all
    locations.each do |location|
      write_request("backup", location.attributes)
    end
  end
end
