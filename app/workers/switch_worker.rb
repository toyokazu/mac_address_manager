class SwitchWorker < Rinda::Worker
  class << self # Class Methods
  end

  def sync(location)
    switch = SSH::Base.get_instance(location.hosttype)
    logger.info "#{switch.class.to_s}: {target: #{location.hostname}, operation: sync_from_serv_to_switch}"
    switch.sync_from_serv_to_switch(location)
  end
end
