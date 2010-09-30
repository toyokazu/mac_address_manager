#!/usr/bin/env ruby
require File.expand_path('../../lib/drb/runner',  __FILE__)
require File.expand_path('../../lib/rinda/worker_runner',  __FILE__)
require File.expand_path('../../lib/rinda/worker',  __FILE__)
require File.expand_path('../../config/rinda_environment',  __FILE__)


if ARGV.size < 1
  puts "usage: upload_aaa_local_db.rb aaa_local_db_file"
  exit 1
end

logger = Logger.new(STDOUT)
client = Rinda::Client.new('switch', :ts_uri => 'druby://localhost:54321', :logger => logger)
tftpd = TFTPD.new
locations = Location.all
SwitchWorker.copy_aaa_local_db(tftpd.path, ARGV[0], locations)
locations.each do |location|
  client.update(location.attributes)
end
