#

module Mysql2BinlogStream
  class Observability
    # graphing lib requires each series be formatted like this
    # TODO: ????????
    # [COUNT, FIELDNAME1, FIELDNAMEX..., FIELD1, FIELDX...]
    # [7,"epoch","idl","recv","send","writ","used","free",26107560,99.46,0,0,0.63,614.52,3767.67

    def self.emit_tsdb(context, metric, now = Time.now.to_f)
      @uuid ||= 0
      @uuid += 1

      @last_tsdbs ||= []
      global_time = Time.now.to_f
      @last_flush ||= -1

      @all_contexts ||= {}
      @all_contexts[context] ||= [[], []] #[2, "epoch", context]

      @all_contexts[context][0] << now
      @all_contexts[context][1] << metric

      if @all_contexts[context][0].length > (8192 * 2)
        @all_contexts[context][0].shift(1)
        @all_contexts[context][1].shift(1)
      end

      if global_time - @last_flush > 2.5
        #puts :flush

        @last_flush = Time.now.to_f

        uuid = @uuid
        tsdb_filename = "/home/app/tmp/metrics/#{uuid}.json"

        output = JSON.dump(@all_contexts)
        fd = File.new(
          tsdb_filename, 
          Fcntl::O_WRONLY | Fcntl::O_EXCL | Fcntl::O_CREAT | Fcntl::O_NOCTTY | Fcntl::O_NONBLOCK
        )
        fd.syswrite(output)
        fd.close

        #TODO: better fd descriptor re-use
        FileUtils.ln_s(tsdb_filename, "/home/app/tmp/metrics/latest.json", force: true)

        @last_tsdbs << tsdb_filename
      end

      #TODO: better fd descriptor re-use
      if @last_tsdbs.length > 4
        old_tsdbs = @last_tsdbs.shift(1)
        if old_tsdbs && !old_tsdbs.empty?
          old_tsdbs.each { |old_tsdb|
            File.unlink(old_tsdb)
          }
        end
      end
    end
  end
end
