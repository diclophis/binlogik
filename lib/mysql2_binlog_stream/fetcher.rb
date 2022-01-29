
module Mysql2BinlogStream
  class Fetcher

    def initialize(blr)
      @log_name = blr
    end

    def fetch!
#      #TODO: implement remote fetching of binlog
#      #TODO: better TMPDIR usage, factory ?????
#      system("mkdir", "-p", "tmp/binlogs")
#      system("mkdir", "-p", "tmp/metrics")
#          cmd = [
#            "/usr/bin/mysqlbinlog",
#            "--host", Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_HOST,
#            "--port", Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_PORT,
#            "--user", Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_USER,
#            "--password=#{Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_PASS}",
#            "--connection-server-id", "1001",
#            "--raw",
#            "--start-position",
#            binlog_files_positions[log_name].to_s,
#            #"--to-last-log",
#            #"--binlog-row-event-max-size", "512",
#            #"--stop-datetime",
#            #(Time.now + 30).strftime('%Y-%m-%d %H:%M:%S'),
#            "--set-charset", "utf8mb4",
#            "--read-from-remote-server",
#            "--result-file", "tmp/binlogs/",
#            log_name
#          ]
#          tmp_bin_log = "tmp/binlogs/#{log_name}"
#
#          o, e, s = Open3.capture3(*cmd)
#          finished_ok = s.success?
#
#          unless finished_ok
#            #TODO: better error handling
#
#            puts [o, e, s].inspect
#            raise "error fetching binlog #{log_name}"
#          end
    end

    def log_name
      @log_name
    end
  end
end
