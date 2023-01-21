#

module Mysql2BinlogStream
  class Cursor
    include Enumerable
    extend Forwardable

    def_delegators :@binary_logs, :each

    def rewind!
      #@binary_logs = Mysql2BinlogStream::SUPERCONFIG.MYSQL_BINARY_LOGS

      #@binary_logs = @binary_logs.split(":")

      database_config = {
         "username" => Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_USER,
         "password" => Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_PASS,
         "host" => Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_HOST,
         "port" => Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_PORT,
         "encoding"=> "utf8mb4",
         "collation"=> "utf8mb4_unicode_ci",
         "strict" => true,
         "reconnect" => true,
         "pool" => 1,
         "timeout" => 20000,
         "checkout_timeout" => 20,
         "connect_timeout" => 5
      }
      mysql_client = Mysql2::Client.new(database_config)
      @binary_logs = mysql_client.query("SHOW BINARY LOGS").to_a
      original_binary_logs_count = @binary_logs.length
      @binary_logs.reject! { |blr|
        blr["Log_name"].nil? || blr["File_size"].nil?
      }
      @binary_logs.collect! { |blr|
        blr["Log_name"]
      }
      #@binary_logs.each { |blr|
      #          log_name = blr["Log_name"]
      #          file_size = blr["File_size"]
      #  log_name = blr["Log_name"]
      #  _, binlog_index = log_name.split(".")
      #  file_size = blr["File_size"]
      #  #binlog_files_handled[log_name] = file_size
      #  #binlog_files_positions[log_name] ||= 4
      #  #TODO: chart metric
      #  #binlog_disk_size = File.stat(tmp_bin_log).size
      #  #Mysql2BinlogStream::Observability.emit_tsdb("matrix.binlog.disk_size", file_size.to_i, binlog_index.to_i)
      #  #puts [:read_over_bytes_serially_slowly].inspect
      #  #puts [log_name, binlog_files_positions[log_name], file_size].inspect
      #}
      #log_name = blr["Log_name"]
      #file_size = blr["File_size"]
      #
      #current_binary_log_index += 1
      #
      #if file_size < 40960
      #  next
      #end
      #
      #if binlog_files_positions[fetched.log_name] == file_size
      #  next
      #end
    end
  end
end
