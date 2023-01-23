
module Mysql2BinlogStream
  class Fetcher

    def initialize(blr)
      @log_name = blr
      fetch!
    end

    def fetch!
      #TODO: implement remote fetching of binlog
      #TODO: better TMPDIR usage, factory ?????
      system("mkdir", "-p", "tmp/binlogs")
      system("mkdir", "-p", "tmp/metrics")
      #puts JSON.dump({"fetch_start" => log_name })
      cmd = [
        "/usr/bin/mysqlbinlog",
        "--host", Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_HOST,
        "--port", Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_PORT,
        "--user", Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_USER,
        "--password=#{Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_PASS}",
        "--connection-server-id", "1001",
        "--raw",
        "--start-position",
        "4",
        #binlog_files_positions[log_name].to_s,
        #"--to-last-log",
        "--binlog-row-event-max-size", "512",
        #"--stop-datetime",
        #(Time.now + 30).strftime('%Y-%m-%d %H:%M:%S'),
        "--set-charset", "utf8mb4",
        "--read-from-remote-server",
        "--result-file", "tmp/binlogs/",
        log_name
      ]
      tmp_bin_log = "tmp/binlogs/#{log_name}"
      #puts cmd.inspect

      o, e, s = Open3.capture3(*cmd)
      finished_ok = s.success?
      #puts JSON.dump({"fetch_stop" => log_name })

      #puts [finished_ok, o, e, s].inspect
    
      unless finished_ok
        #TODO: better error handling
    
        puts [o, e, s].inspect
        raise "error fetching binlog #{log_name}"
      end
    end

    def log_name
      @log_name
    end
  end
end
