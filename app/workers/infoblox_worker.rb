class InfobloxWorker < Rinda::Worker
  class << self # Class Methods
  end

  def sync(task_file)
    cmd = "#{RAILS_ROOT}/script/infoblox/infoblox.pl -f #{task_file}"
    logger.info cmd
    logger.info `#{cmd}`
  end
end
