#

#TODO: build out local tooling abstraction

module Mysql2BinlogStream
  class Cli
    def self.main(argv)
      case argv[0]
        when "--follow"
          self.follow
        when "--workload"
          self.workload
      else
        raise "unknown action"
      end
    end

    def self.workload
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

      loop do
        mysql_client.query('/*XAX ' + JSON.dump({"foo" => Time.now.to_f}) + ' XAX*/ INSERT INTO test.test VALUES()')
      end
    end

    def self.follow
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

      binlog_files_handled = {}
      binlog_files_positions = {}

      #TODO: better TMPDIR usage, factory ?????
      system("mkdir", "-p", "tmp/binlogs")
      system("mkdir", "-p", "tmp/metrics")

      while true
        binary_logs = mysql_client.query("SHOW BINARY LOGS").to_a

        binary_logs.reject! { |blr|
          blr["Log_name"].nil? || blr["File_size"].nil?
        }

        binary_logs.each { |blr|
          log_name = blr["Log_name"]
          _, binlog_index = log_name.split(".")
          file_size = blr["File_size"]

          binlog_files_handled[log_name] = file_size
          binlog_files_positions[log_name] ||= 4

          #TODO: chart metric
          #binlog_disk_size = File.stat(tmp_bin_log).size
          #Mysql2BinlogStream::Observability.emit_tsdb("matrix.binlog.disk_size", file_size.to_i, binlog_index.to_i)
          #puts [:read_over_bytes_serially_slowly].inspect
          #puts [log_name, binlog_files_positions[log_name], file_size].inspect
        }

        binary_logs.each { |blr|
          log_name = blr["Log_name"]
          file_size = blr["File_size"]

          if binlog_files_positions[log_name] == file_size
            next
          end

          _, binlog_index = log_name.split(".")

          cmd = [
            "/usr/bin/mysqlbinlog",
            "--host", Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_HOST,
            "--port", Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_PORT,
            "--user", Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_USER,
            "--password=#{Mysql2BinlogStream::SUPERCONFIG.MYSQL_SERVICE_PASS}",
            "--connection-server-id", "1001",
            "--raw",
            "--start-position",
            binlog_files_positions[log_name].to_s,
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

            puts [o, e, s].inspect
            raise "error fetching binlog #{log_name}"
          end

          tmp_bin_log = "tmp/binlogs/#{log_name}"

          stream = Mysql2BinlogStream::Stream.new

          reader = Mysql2BinlogStream::BinlogReader.new(tmp_bin_log)
          reader.seek(binlog_files_positions[log_name])

          binlog = Mysql2BinlogStream::Binlog.new(reader)

          binlog.checksum = :crc32 #TODO: detect crc???
          binlog.ignore_rotate = true #TODO: rotate I think is super-critical!!!

          #:write_rows_event_v2, :update_rows_event_v2
          #:rows_query_log_event
          binlog.filter_event_types = [:rows_query_log_event]

          start_time = Time.now

          binlog.each_event { |event|
            last_known_position_for_binlog = binlog_files_positions[log_name]

            if event[:position] > last_known_position_for_binlog
              global_counter += 1 
              event_type_counter[event[:type]] ||= 0
              event_type_counter[event[:type]] += 1
              header_timestamp = event[:header][:timestamp]
              case event[:type]
                when :rows_query_log_event
                  event2 = event[:event]
                  if query = event2[:query]
                    if xax_json = stream.strstr_method(query)
                      if (global_counter % 100) == 0
                        puts [global_counter, Time.now.to_f - JSON.load(xax_json)["foo"]].inspect
                      end
                    end
                  end
                #when :write_rows_event_v2, :update_rows_event_v2
                #  slugified_table_name = [event[:event][:table][:db], event[:event][:table][:table]].join("_").downcase
                #  rows_changed = event[:event][:row_image].length
                #  if event2 = event[:event]
                #    if table = event2[:table]
                #      if row_images = event2[:row_image]
                #        i = 0
                #        row_images.each { |row_image|
                #          before = row_image[:before]
                #          after = row_image[:after]
                #          #TODO: puts [i+=1, rows_changed, slugified_table_name, (before ? before[:image] : nil), (after ? after[:image] : nil)].inspect
                #        }
                #      end
                #    end
                #  end
              else
                #TODO
              end

              binlog_files_positions[log_name] = event[:position]

              if event[:type] == :rotate_event
                binlog_files_positions[log_name] = event[:header][:next_position]
              end

              #if (rand < 0.01)
              #  Mysql2BinlogStream::Observability.emit_tsdb("stat.lag", (Time.now - Time.at(header_timestamp)))
              #  Mysql2BinlogStream::Observability.emit_tsdb("counter.global", global_counter)
              #  Mysql2BinlogStream::Observability.emit_tsdb("counter.#{event[:type]}", event_type_counter[event[:type]])
              #end
            end
          }

          #puts [:OK, binlog_files_positions, binlog_files_handled].inspect
          #sleep 0.1
        }
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
