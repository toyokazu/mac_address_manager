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
  # row[0]\trow[1]\trow[2]\n
  # row[0]  row[1]  row[2]
  # hostname\tmac_addr\tdescription\n
  # hostname  mac_addr  description
  # myhost  112233445566  Apple Xserve, 14225, Oomoto Lab.
  def update_and_unlock(options = {})
    mac_addrs = MacAddress.all(:conditions => {:group_id => options[:group_id]})
    CSV::Reader.parse(options[:csv], "\t") do |row|
      # get older entry
      match_mac_addrs, mac_addrs = mac_addrs.partition {|item| item.mac_addr == row[1]}
      if match_mac_addrs.size == 0
        params = {:group_id => options[:group_id], :hostname => row[0], :mac_addr => row[1], :description => row[2]}
        MacAddress.create(params)
        logger.info("create entry: #{row[1]}")
      else
        mac_addr = match_mac_addrs.first
        mac_addr.hostname = row[0]
        mac_addr.description = row[2]
        mac_addr.save
        logger.info("update entry: #{row[1]}")
      end
    end
    # The rest entries are deleted in the uploaded CSV file
    mac_addrs.each do |mac_addr|
      mac_addr.destroy
    end
    unlock(options[:group_id])
  end

  class << self # Class Methods
  end
end
