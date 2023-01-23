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
        statement = mysql_client.prepare("/*#{xax_tag} " + JSON.dump({"foo" => Time.now.to_f}) + " #{xax_tag}*/ INSERT INTO test.test VALUES(NULL, FROM_UNIXTIME(?), ?, ?)")
        result1 = statement.execute(Time.now.to_f, SecureRandom.hex, Random.urandom(1024))

        #r2 = mysql_client.query("SELECT COUNT(*) FROM test.test")
        #puts r2.inspect
        #sleep 0.5
      end
    end

    def self.follow(xax_tag)
      scene_xids = {}
      demo_counter = 0

      global_counter = 0
      event_type_counter = {}

      stream = Mysql2BinlogStream::Stream.new(xax_tag)

      cursor = Mysql2BinlogStream::Cursor.new

      #scene_this_blr = {}

      while true
        #puts "loop"

        cursor.rewind!

        cursor.each { |blr|
          #puts "each cursor step"

          #has_scene_this_blr = scene_this_blr[blr]

          #if has_scene_this_blr
          #else
            fetched = Mysql2BinlogStream::Fetcher.new(blr)
            #puts "tmp/binlogs/" + fetched.log_name
            #puts system("ls -l tmp/binlogs")

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
              event_type_counter[event[:type]] ||= 0
              event_type_counter[event[:type]] += 1
              header_timestamp = event[:header][:timestamp]

              #$stderr.write("\r" + Time.at(header_timestamp).to_s)

              case event[:type]
                when :xid_event
                  if last_xid

                    #puts "flushing ---- #{last_xid[:xid]}"
                    #puts "changes count: #{last_xid[:changes].length} query count: #{last_xid[:xax_query].length}"
                    #puts "tables changed: #{last_xid[:changes].collect { |change| change[:table][:table] }.inspect}"
                    #puts "queries: #{last_xid[:xax_query].collect { |xax_query| xax_query[0..32] + '...' }.inspect}"
                    #puts "request_details: #{last_xid[:xax_json].collect { |xax_json| xax_json["request_uuid"] }.uniq}"
                    #puts "gtid: #{last_xid[:gtid]}"
                    #parsed_xid_json_hash = Digest::SHA256.hexdigest(parsed_xid_json)

                    if scene_xids[last_xid[:gtid]].nil?
                      demo_counter += 1

                      parsed_xid_json = JSON.dump(last_xid)
                      scene_xids[last_xid[:gtid]] = parsed_xid_json
                      if ((demo_counter % 1000) == 0)
                        puts parsed_xid_json
                      end
                    end

                    #puts
                    #puts last_xid.inspect
                    #puts
                  end

                  last_xid = event[:event]
                  #puts
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
                  #puts event.inspect
                  xax_json = nil
                  query_stripped = nil
                  anon_query = nil

                  if query = event2[:query]
                    if xax_bits = stream.strstr_method(query)
                      xax_json_raw, query_stripped = *xax_bits
                      xax_json = JSON.load(xax_json_raw)
                      xax_query = query_stripped
                    else
                      anon_query = query
                    end
                  end

                  if last_xid && xax_json && query_stripped
                    #puts "stacking... xid:#{last_xid[:xid]} #{event[:type]} @ #{event[:filename]}:#{event[:position]}"

                    last_xid[:rows_query_binlog_position] << "#{event[:filename]}:#{event[:position]}"
                    last_xid[:xax_json] << xax_json
                    last_xid[:xax_query] << query_stripped
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

                when :format_description_event, :previous_gtids_log_event, :query_event, :table_map_event
                  #NOTE: safe to ignore
                  #puts event.inspect

                when :gtid_log_event
                  if last_xid
                    last_xid[:gtid] = event[:event][:gtid]
                  end
 
              else
                #TODO TODO
                puts "ignoring... #{event[:type]}"
                puts event.inspect

              end
            }
        
          #  scene_this_blr[blr] = true
          #end
        }

        #break
        #sleep 1
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
