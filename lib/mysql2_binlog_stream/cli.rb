#

#TODO: build out local tooling abstraction

module Mysql2BinlogStream
  class Cli
    def self.main
      global_counter = 0

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
         "checkout_timeout" => 20
      }

      mysql_client = Mysql2::Client.new(database_config)
      create_test_db = mysql_client.query('/* {"foo":"bar"} */ CREATE DATABASE test_' + Time.now.to_i.to_s)

      binlog_files_handled = {}

      #TODO: better TMPDIR usage, factory ?????
      system("mkdir", "-p", "tmp/binlogs")
      system("mkdir", "-p", "tmp/metrics")

      while true
        binary_logs = mysql_client.query("SHOW BINARY LOGS").to_a

        log_name = file_size = nil

        #TODO: build out diskspace safety check mechanism
        (binary_logs[0..-2]).each { |blr|
          log_name = blr["Log_name"]
          file_size = blr["File_size"]

          if binlog_files_handled[log_name] == file_size
            #puts [:skipping, log_name]
            next
          else
            break
          end
        }

        unless log_name
          puts [:relooping, :still_waiting]
          next
        end

        puts [:fetching, log_name].inspect

        cmd = [
          "/usr/bin/mysqlbinlog",
          "--host", Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_HOST,
          "--port", Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_PORT,
          "--user", Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_USER,
          "--password=#{Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_PASS}",
          "--connection-server-id", "1001",
          "--raw",
          #"--to-last-log",
          #"--binlog-row-event-max-size", "512",
          "--set-charset", "utf8mb4",
          "--read-from-remote-server",
          "--result-file", "tmp/binlogs/",
          log_name
        ]

        o, e, s = Open3.capture3(*cmd)
        finished_ok = s.success?

        unless finished_ok
          #TODO: better error handling

          #puts [o, e, s].inspect
          raise "error fetching binlog #{log_name}"
        end

        puts [:processing, log_name].inspect

        tmp_bin_log = "tmp/binlogs/#{log_name}"
        reader = Mysql2BinlogStream::BinlogReader.new(tmp_bin_log)
        reader.tail = false
        binlog = Mysql2BinlogStream::Binlog.new(reader)
        binlog.checksum = :crc32
        binlog.ignore_rotate = true #TODO: rotate I think is super-critical!!!

        puts [:read_over_bytes_serially_slowly].inspect
        start_time = Time.now
        event_counter = 0
        event_type_counter = {}
        binlog.each_event { |event|
          event_counter += 1
          event_type_counter[event[:type]] ||= 0
          event_type_counter[event[:type]] += 1

          #if event[:type] == :query_event
          #  puts event[:event][:query].inspect
          #end

          global_counter += 1 
          Mysql2BinlogStream::Observability.emit_tsdb("global.counter", global_counter)
        }

        #TODO: chart metric
        #puts [:handled_binlog_size, tmp_bin_log, event_counter, File.stat(tmp_bin_log).size, event_type_counter].inspect
        #TODO: chart metric
        puts [:handled_binlog_size, "%0.2f" % (Time.now - start_time)].inspect
        binlog_files_handled[log_name] = file_size
      end
    end
  end
end
