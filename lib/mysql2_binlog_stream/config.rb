#

module Mysql2BinlogStream
  class Config < SuperConfig2
    attr_reader "MYSQL_SERVICE_HOST", s("127.0.0.1")
    attr_reader "MYSQL_SERVICE_PORT", s("3306")
    attr_reader "MYSQL_SERVICE_USER", s("root")
    attr_reader "MYSQL_SERVICE_PASS", s("password")
  end
end
