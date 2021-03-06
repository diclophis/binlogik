#

#TODO: unit test module
#TODO: read-live stream????

module Mysql2BinlogStream
  # Read a binary log from a file on disk.
  class BinlogReader
    MAGIC_SIZE  = 4
    MAGIC_VALUE = 1852400382

    def initialize(filename)
      open_file(filename)
    end

    def verify_magic
      if (magic = read(MAGIC_SIZE).unpack("V").first) != MAGIC_VALUE
        raise MalformedBinlogException.new("Magic number #{magic} is incorrect")
      end
    end

    def open_file(filename)
      @filename = File.basename(filename)
      @binlog   = StringIO.new(IO.binread(filename))
      @binlog.binmode

      verify_magic
    end

    #TODO ?????????????
    #TODO: is rotate required???
    #TODO: is rotate required to ensure consistent stream
    #def rotate(filename, position)
    #  retries = 10
    #  begin
    #    open_file(filename)
    #    seek(position)
    #  rescue Errno::ENOENT
    #    # A rotate event will be seen in the previous log file before the
    #    # new file exists. Retry a few times with a little sleep to give
    #    # the server a chance to create the new file.
    #    if (retries -= 1) > 0
    #      sleep 0.01
    #      retry
    #    else
    #      raise
    #    end
    #  end
    #end

    def filename
      @filename
    end

    def position
      @binlog.tell
    end

    def rewind
      seek(MAGIC_SIZE)
    end

    def seek(pos)
      @binlog.seek(pos)
    end

    def unget(char)
      @binlog.ungetc(char)
    end

    def end?
      @binlog.eof?
    end

    def remaining(header)
      header[:payload_end] - @binlog.tell
    end

    def skip(header)
      seek(header[:next_position])
    end

    def read(length)
      return "" if length == 0
      data = @binlog.read(length)
      if !data
        raise MalformedBinlogException.new
      elsif data.length == 0
        raise ZeroReadException.new
      elsif data.length < length
        raise ShortReadException.new
      end
      data
    end
  end
end
