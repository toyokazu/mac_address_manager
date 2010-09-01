require 'csv'
class UpdateWorker < Rinda::Worker
  include MonitorMixin
  @@lock_table = {}

  # called via DRbObject interface
  def lock(group_id) 
    synchronize do
      if @@lock_table[group_id].nil?
        @@lock_table[group_id] = group_id
        return true
      end
      false
    end
  end

  def unlock(group_id)
    synchronize do
      @@lock_table.delete(group_id)
    end
  end

  # wrapper interface for Rinda::Client
  def update_and_unlock_request(group_id, csv)
    write_request("update_and_unlock", {:group_id => group_id, :csv => csv})
  end

  # options
  # group_id: uploading group's id
  # csv: csv string
  #
  # assume input CSV data format as follows:
  #
  # row[0]\trow[1]\trow[2]\nrow[3]
  # row[0]  row[1]  row[2]  row[3]
  # hostname\tmac_addr\tdescription\tip_address\n
  # hostname  mac_addr  description ip_address
  # myhost  11:22:33:44:55:66  Apple Xserve, 14225, Oomoto Lab.  133.101.56.100
  #
  # ip_address could be null. If not specified, free address is choosen from
  # IP address range assigned to the user (group).
  def update_and_unlock(options = {})
    mac_addrs = MacAddress.all(:conditions => {:group_id => options[:group_id]})
    group = Group.find(options[:group_id])
    param_list = []
    CSV::Reader.parse(options[:csv], "\t") do |row|
      ip_addr = nil
      # ip address selection
      if row[3].nil?
        ip_addr = Network.next_ip(group.user)
      else
        ip_addr = IPAddr.new(row[3])
      end
      # get older entry
      match_mac_addrs, mac_addrs = mac_addrs.partition {|item| item.hostname == row[0] && item.mac_addr == row[1]}
      if match_mac_addrs.size == 0
        ip_param = ip_addr.ipv4? ? {:ipv4_addr => ip_addr.to_s} : {:ipv6_addr => ip_addr.to_s}
        params = {:group_id => options[:group_id], :hostname => row[0], :mac_addr => row[1], :description => row[2]}.merge(ip_param)
        param_list << params
        logger.info("create entry: #{row[1]}")
      else
        mac_addr = match_mac_addrs.first
        mac_addr.hostname = row[0]
        mac_addr.mac_addr = row[1]
        mac_addr.description = row[2]
        if ip_addr.ipv4?
          mac_addr.ipv4_addr = ip_addr.to_s
        else
          mac_addr.ipv6_addr = ip_addr.to_s
        end
        mac_addr.save
        logger.info("update entry: #{row[1]}")
      end
    end
    # The rest entries are deleted in the uploaded CSV file
    mac_addrs.each do |mac_addr|
      mac_addr.destroy
    end
    param_list.each do |params|
      mac_address = MacAddress.create(params)
      mac_address.location_ids = group.location_ids
      mac_address.save
    end
    unlock(options[:group_id])
  end

  class << self # Class Methods
  end
end
