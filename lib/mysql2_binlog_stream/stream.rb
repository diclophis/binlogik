#

module Mysql2BinlogStream
  class Stream
    XAX_PREFIX = "/*XAX"
    XAX_PREFIX_LENGTH = XAX_PREFIX.length
    XAX_SUFFIX = "XAX*/"
    XAX_SUFFIX_LENGTH = XAX_SUFFIX.length

    def subscribe
      #TODO: yield each msg
    end

    def strstr_method(inp)
      left = inp.index(XAX_PREFIX)
      right = inp.index(XAX_SUFFIX)
      if left && right
        inp.slice(left + XAX_PREFIX_LENGTH, right - XAX_SUFFIX_LENGTH)
      end
    end
  end
end
