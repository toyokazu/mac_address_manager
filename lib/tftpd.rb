# for FileUtils.mkdir_p
require 'fileutils'
require 'yaml'

class TFTPD
  attr_reader :user, :path, :default_addr

  def initialize
    @config = YAML.load_file("#{RAILS_ROOT}/config/tftpd.yml")
    @user = @config["user"] || `/usr/bin/env id -un`.strip
    @path = @config["path"] || "#{RAILS_ROOT}/tmp/tftproot"
    @default_addr = @config["default_addr"]
  end

  def addr_option
    return "-a #{@default_addr}" if !@default_addr.nil?
    nil
  end

  def create_path
    FileUtils.mkdir_p(@path) if !File.exists?(@path)
  end
end
