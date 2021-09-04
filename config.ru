# This file is used by Rack-based servers to start the application.

$gem_dir = File.dirname(File.dirname(File.realpath(__FILE__)))
lib = File.join($gem_dir, "lib")
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'mysql2_binlog_stream'
require 'webrick'

module WebrickOverrideOptions
  def default_options
    webrick_options = {
      :Port               => 9292,
      :environment        => (ENV['RACK_ENV'] || "development").dup,
      :Logger             => WEBrick::Log::new($stdout, WEBrick::Log::DEBUG),
      :MaxClients         => 32
    }

    super.merge webrick_options
  end
end

Rack::Server.send(:prepend, WebrickOverrideOptions)

#public_urls = 
#  ["/favicon.ico", "/index.html", "/index.js", "/fonts.css", "/vanilla.css"]
#
#use(
#  Rack::Static, {
#    :urls => public_urls,
#    :root => 'public'
#  }
#)

@app = run(Mysql2BinlogStream::App)
