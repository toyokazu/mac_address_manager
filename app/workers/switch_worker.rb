class SwitchWorker < Rinda::Worker
  class << self # Class Methods
  end

  def update(location)
    switch = SSH::Base.get_instance(location.hosttype)
    logger.info "#{switch.class.to_s}: {target: #{location.hostname}, operation: sync_from_serv_to_switch}"
    switch.sync_from_serv_to_switch(location)
  end

  def backup(location)
    switch = SSH::Base.get_instance(location.hosttype)
    logger.info "#{switch.class.to_s}: {target: #{location.hostname}, operation: sync_from_switch_to_serv}"
    switch.sync_from_switch_to_serv(location)
  end

  def backup_all(options = {})
    locations = Location.all
    locations.each do |location|
      write_request("backup", location)
    end
  end
end
