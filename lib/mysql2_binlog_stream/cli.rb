# encoding: UTF-8

#TODO: build out local tooling abstraction

module Mysql2BinlogStream
  class Cli
    def self.main(argv)
      case argv[0]
        when /--debug-follow=/
          self.follow(argv[0].split("=")[1])
        when /--debug-workload=/
          self.workload(argv[0].split("=")[1])

      else
        raise "unknown action #{argv.inspect}"
      end
    end

    def self.workload(xax_tag)
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
      
      loop do
        statement1 = mysql_client.prepare("/*#{xax_tag} " + JSON.dump({"bit" => "ins", "foo" => Time.now.to_f}) + " #{xax_tag}*/ INSERT INTO test.test VALUES(NULL, FROM_UNIXTIME(?), ?, ?)")
        statement1.execute(Time.now.to_f, "foo-#{SecureRandom.hex[0..5]}-bar", Random.urandom(32536.0 * 2.0 * rand))

        id_stat = mysql_client.prepare("SELECT t1.id FROM test.test AS t1 JOIN (SELECT id FROM test.test ORDER BY RAND() LIMIT 10) as t2 ON t1.id=t2.id LIMIT 1")
        id_result = id_stat.execute
        id_a = id_result.to_a

        unless id_a.empty?
          statement2 = mysql_client.prepare("/*#{xax_tag} " + JSON.dump({"bit" => "upd", "foo" => Time.now.to_f}) + " #{xax_tag}*/ UPDATE test.test SET description = ?, extra = ? WHERE test.id= ?")
          result2 = statement2.execute("foo-#{SecureRandom.hex[0..5]}-bar", Random.urandom(32536.0 * 2.0 * rand), id_a[0]["id"])
        end
      end
    end

    def self.follow(xax_tag)
      seen_xids = {}
      demo_counter = 0
      loop_counter = 0
      global_counter = 0
      event_type_counter = {}
      skip_counter = 0

      stream = Mysql2BinlogStream::Stream.new(xax_tag)
      cursor = Mysql2BinlogStream::Cursor.new

      while true
        loop_counter += 1

        cursor.rewind!

        cursor.each { |blr|
            fetched = Mysql2BinlogStream::Fetcher.new(blr)
            reader = Mysql2BinlogStream::BinlogReader.new("tmp/binlogs/" + fetched.log_name)
            binlog = Mysql2BinlogStream::Binlog.new(reader)

            binlog.checksum = :crc32 #TODO: detect crc???
            binlog.ignore_rotate = true #TODO: rotate I think is super-critical!!!

            binlog.filter_event_types = [
              :unknown_event            ,
              :query_event              ,
              :stop_event               ,
              :rotate_event             ,
              :intvar_event             ,
              :append_block_event       ,
              :delete_file_event        ,
              :rand_event               ,
              :user_var_event           ,
              :format_description_event ,
              :xid_event                ,
              :begin_load_query_event   ,
              :execute_load_query_event ,
              :table_map_event          ,
              :write_rows_event_v1      ,
              :update_rows_event_v1     ,
              :delete_rows_event_v1     ,
              :incident_event           ,
              :heartbeat_log_event      ,
              :ignorable_log_event      ,
              :rows_query_log_event     ,
              :write_rows_event_v2      ,
              :update_rows_event_v2     ,
              :delete_rows_event_v2     ,
              :gtid_log_event           ,
              :anonymous_gtid_log_event ,
              :previous_gtids_log_event ,
              :transaction_context_event,
              :view_change_event        ,
              :xa_prepare_log_event     ,
              :table_metadata_event
            ]

            start_time = Time.now

            last_row = nil
            last_xid = nil

            binlog.each_event { |event|
              global_counter += 1
              skip_counter += 1

              event_type_counter[event[:type]] ||= 0
              event_type_counter[event[:type]] += 1
              header_timestamp = event[:header][:timestamp]

              case event[:type]
                when :xid_event
                  if last_xid
                    if seen_xids[last_xid[:gtid]].nil?
                      demo_counter += 1
                      seen_xids[last_xid[:gtid]] = true


                      before = last_xid[:changes][0][:row_image][0][:before]
                      after = last_xid[:changes][0][:row_image][0][:after]


                        after_map = {}

                        last_xid[:map_entry][:columns].collect.with_index { |column, i|
                          b = begin
                                             case column[:type]
                                               when :blob
                                                 after[:image][i][i].pack('U*')
                                             else
                                               after[:image][i][i]
                                             end
                                           end
                          after_map[column[:column_name]] = b
                        }

                      json_diff = nil
                      
                      if before && after
                        before_map = {}
                        
                        last_xid[:map_entry][:columns].each.with_index { |column, i|
                          b = begin
                                             case column[:type]
                                               when :blob
                                                 before[:image][i][i].pack('U*')
                                             else
                                               before[:image][i][i]
                                             end
                                           end
                          before_map[column[:column_name]] = b
                        }

                        json_diff = JsonDiff.diff(before_map, after_map)
                      else
                        json_diff = JsonDiff.diff(nil, after_map)
                      end

                      xxx = JSON.dump({:xax_id => [last_xid[:map_entry][:db], last_xid[:map_entry][:table], after_map["id"]].join("/"), :xax_json => last_xid[:xax_json]}) # :xax_diff => json_diff

                      puts xxx
                      puts
                      
                      yyy = JSON.parse(xxx)

                      if ((demo_counter % 100) == 0)
                        seconds_behind = Time.now.to_f - (yyy["xax_json"][0]["foo"].to_f)
                        puts [:lag, seconds_behind, :loop, loop_counter, :skip, skip_counter, :uniq, demo_counter, fetched.log_name].inspect
                      end

                      skip_counter = 0

                      #  TODO: xax_query
                      #  last_xid[:changes][0][:row_image][0][:after][:image][2][2].pack('U*'),
                      #  last_xid[:changes][0][:row_image][0][:after][:image][3][3].length,
                    end
                  end

                  last_xid = event[:event]
                  #puts "opening ... xid:#{last_xid[:xid]} @ #{event[:filename]}:#{event[:position]}"

                  last_xid[:timestamp] = header_timestamp
                  last_xid[:binlog_position] = "#{event[:filename]}:#{event[:position]}"
                  last_xid[:changes] = []
                  last_xid[:xax_json] = []
                  last_xid[:xax_query] = []
                  last_xid[:anon_query] = []
                  last_xid[:rows_update_binlog_position] = []
                  last_xid[:rows_query_binlog_position] = []

                when :write_rows_event_v2, :update_rows_event_v2 #, :xid_event, :gtid_log_event
                  if last_xid
                    #puts "stacking... xid:#{last_xid[:xid]} #{event[:type]} @ #{event[:filename]}:#{event[:position]}"

                    last_xid[:changes] << event[:event]
                    last_xid[:rows_update_binlog_position] << "#{event[:filename]}:#{event[:position]}"
                  end

                when :rows_query_log_event
                  event2 = event[:event]
                  xax_json = nil
                  query_stripped = nil
                  anon_query = nil

                  if query = event2[:query]
                    if xax_bits = stream.strstr_method(query)
                      xax_json_raw, query_stripped = *xax_bits
                      xax_json = JSON.load(xax_json_raw)
                      xax_query = query_stripped.each_codepoint.to_a
                    else
                      anon_query = query
                    end
                  end

                  if last_xid && xax_json && query_stripped
                    #puts "stacking... xid:#{last_xid[:xid]} #{event[:type]} @ #{event[:filename]}:#{event[:position]}"

                    last_xid[:rows_query_binlog_position] << "#{event[:filename]}:#{event[:position]}"
                    last_xid[:xax_json] << xax_json
                    last_xid[:xax_query] << query_stripped.each_codepoint.to_a
                  elsif last_xid && anon_query
                    #puts "stacking... xid:#{last_xid[:xid]} #{event[:type]} @ #{event[:filename]}:#{event[:position]}"
                    last_xid[:rows_query_binlog_position] << "#{event[:filename]}:#{event[:position]}"
                    last_xid[:anon_query] << anon_query
                  else
                    #puts "partial SKIPPING ... #{xax_bits.inspect}"
                    #sleep 0.001
                  end

                when :anonymous_gtid_log_event
                  #puts event[:event][:payload].each_byte.map { |b| b.to_s(16) }.join.inspect
                  #TODO: non-gtid stuff here???
                  if last_xid
                    last_xid[:gtid] = event[:event][:payload].each_byte.map { |b| b.to_s(16) }.join
                  end

                when :table_map_event
                  if last_xid
                    last_xid[:map_entry] = event[:event][:map_entry]
                  end

                #when :format_description_event, :previous_gtids_log_event, :query_event
                #  #NOTE: safe to ignore
                #  #puts event.inspect

                when :gtid_log_event
                  if last_xid
                    last_xid[:gtid] = event[:event][:gtid]
                  end

              else
                #TODO TODO
                #puts "ignoring... #{event[:type]}"
                #puts event.inspect

              end
            }
        }
      end
    end
  end
end
