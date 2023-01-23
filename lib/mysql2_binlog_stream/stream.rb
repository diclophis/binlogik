#

module Mysql2BinlogStream
  class Stream
    def initialize(xax_tag = "XAX")
      @XAX_PREFIX = "/*#{xax_tag}"
      @XAX_PREFIX_LENGTH = @XAX_PREFIX.length
      @XAX_SUFFIX = "#{xax_tag}*/"
      @XAX_SUFFIX_LENGTH = @XAX_SUFFIX.length
    end

    def strstr_method(inp)
      left = inp.index(@XAX_PREFIX)
      right = inp.index(@XAX_SUFFIX)
      if left && right
        return inp.slice(left + @XAX_PREFIX_LENGTH, right - @XAX_SUFFIX_LENGTH), inp.slice(right + @XAX_SUFFIX_LENGTH, inp.length)
      end
    end
  end
end
