# for FileUtils.mkdir_p
require 'fileutils'
require 'yaml'

namespace :infoblox do
  def output_error(error, message)
    puts "Error occurred during #{message}."
    puts "#{error.class}: #{error.message}"
    puts error.backtrace
  end

  task :config => :environment do
    begin
      #@config = YAML.load_file("#{RAILS_ROOT}/config/infoblox.yml")
      @path = "#{RAILS_ROOT}/tmp/infoblox"
    rescue => error
      output_error(error, "reading configuration file")
    end
  end

  desc "init infoblox"
  task :init => :config do
    begin
      FileUtils.mkdir_p(@path) if !File.exists?(@path)
    rescue => error
      output_error(error, "initialize infoblox environments")
    end
  end
end
