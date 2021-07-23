#

#TODO: build out local tooling abstraction

module Mysql2BinlogStream
  class Cli
    def self.main
      global_counter = 0
      event_type_counter = {}

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

        #log_name = file_size = nil

        ##TODO: build out diskspace safety check mechanism
        #(binary_logs[0..-2]).each { |blr|
        #  log_name = blr["Log_name"]
        #  file_size = blr["File_size"]
        #  if binlog_files_handled[log_name] == file_size
        #    #puts [:skipping, log_name]
        #    next
        #  else
        #    break
        #  end
        #}
        #unless log_name
        #  puts [:relooping, :still_waiting]
        #  next
        #end


        binary_logs.each { |blr|
          log_name = blr["Log_name"]
          _, binlog_index = log_name.split(".")
          file_size = blr["File_size"]
          #TODO: chart metric
          #binlog_disk_size = File.stat(tmp_bin_log).size
          Mysql2BinlogStream::Observability.emit_tsdb("matrix.binlog.disk_size", file_size.to_i, binlog_index.to_i)
          #puts [:read_over_bytes_serially_slowly].inspect
        }


        binary_logs.each { |blr|
          log_name = blr["Log_name"]
          file_size = blr["File_size"]

          _, binlog_index = log_name.split(".")

          #puts [:fetching, ].inspect

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
          #puts [:processing, log_name].inspect

          tmp_bin_log = "tmp/binlogs/#{log_name}"
          puts tmp_bin_log

          reader = Mysql2BinlogStream::BinlogReader.new(tmp_bin_log)
          binlog = Mysql2BinlogStream::Binlog.new(reader)
          binlog.checksum = :crc32 #TODO: detect crc???
          binlog.ignore_rotate = true #TODO: rotate I think is super-critical!!!


          start_time = Time.now
          binlog.each_event { |event|
            global_counter += 1 

            event_type_counter[event[:type]] ||= 0
            event_type_counter[event[:type]] += 1

            header_timestamp = event[:header][:timestamp]

            case event[:type]
              when :write_rows_event_v2, :update_rows_event_v2
                slugified_table_name = [event[:event][:table][:db], event[:event][:table][:table]].join("_").downcase

                rows_changed = event[:event][:row_image].length

                Mysql2BinlogStream::Observability.emit_tsdb("stat.#{slugified_table_name}.rows_changed", rows_changed, header_timestamp.to_f)
            else
              #TODO
              #puts event.inspect
            end

            if (rand < 0.01)
              Mysql2BinlogStream::Observability.emit_tsdb("stat.lag", (Time.now - Time.at(header_timestamp)))
              Mysql2BinlogStream::Observability.emit_tsdb("counter.global", global_counter)
              Mysql2BinlogStream::Observability.emit_tsdb("counter.#{event[:type]}", event_type_counter[event[:type]])
            end
          }
        }

        puts [:looping].inspect
        sleep 5
      end
    end
  end
end

#stat.binlog_disk_size
#counter.global
#counter.anonymous_gtid_log_event
#counter.format_description_event
#counter.previous_gtids_log_event
#counter.query_event
#counter.rotate_event
#counter.rows_query_log_event
#counter.stop_event
#counter.table_map_event
#counter.write_rows_event_v2
#counter.xid_event
