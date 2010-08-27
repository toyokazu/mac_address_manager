class SwitchWorker < Rinda::Worker
  class << self # Class Methods
  end

  # location is a Hash of the Location attributes (Location#attributes)
  def update(location)
    switch = SSH::Base.get_instance(location)
    logger.info "#{switch.class.to_s}: {target: #{switch.hostname}, operation: sync_from_serv_to_switch}"
    switch.sync_from_serv_to_switch
  end

  # location is a Hash of the Location attributes (Location#attributes)
  def backup(location)
    switch = SSH::Base.get_instance(location)
    logger.info "#{switch.class.to_s}: {target: #{switch.hostname}, operation: sync_from_switch_to_serv}"
    switch.sync_from_switch_to_serv
  end

  def backup_all(options = {})
    locations = Location.all
    locations.each do |location|
      write_request("backup", location.attributes)
    end
  end
end
