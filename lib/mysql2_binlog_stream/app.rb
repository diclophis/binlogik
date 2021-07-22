#

module Mysql2BinlogStream
  class App
    def self.call(env)
      #puts env.inspect
      #TODO: gather tmp/metrics json blobs and emit prometheus or json blob
      #NOTE: this is time-ordered-data, but could be send randomly to cross check
      #NOTE: !?
      [200, {
        "Access-Control-Allow-Origin" => "*",
        "Content-Type" => "application/json"
      }, StringIO.new(IO.binread("/home/app/tmp/metrics/latest.json"))]
    end
  end
end
