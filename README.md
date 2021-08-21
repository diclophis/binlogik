# binlogik

binlogik is a ruby-based mysql binlog utility.

its default mode emits mysql binlog query and row events to stdout, and runs as a kubernetes pod, detecting `MYSQL_SERVICE` from the `ENV` via `superconfig2`

# related work / research links

https://dev.mysql.com/doc/internals/en/query-event.html

https://dev.mysql.com/doc/internals/en/binlog-event.html

https://dev.mysql.com/doc/internals/en/com-binlog-dump.html

https://dev.mysql.com/doc/refman/5.7/en/purge-binary-logs.html

https://dev.mysql.com/doc/dev/mysql-server/8.0.21/classQuery__log__event.html

https://dev.mysql.com/doc/internals/en/xid-event.html

https://www.rubydoc.info/gems/mysql_binlog/0.3.2/MysqlBinlog

https://dev.mysql.com/doc/dev/mysql-server/latest/statement__events_8h_source.html

https://dev.mysql.com/doc/refman/5.7/en/mysqlbinlog.html#option_mysqlbinlog_start-position

https://github.com/y310/kodama

https://github.com/krowinski/php-mysql-replication/blob/41073226e6c35c793499ba928ae02d81f1a47b8a/src/MySQLReplication/BinLog/BinLogSocketConnect.php

https://github.com/jeremycole/mysql_binlog/blob/master/lib/mysql_binlog/binlog.rb

https://github.com/jeremycole/mysql_binlog/blob/master/lib/mysql_binlog/reader/binlog_stream_reader.rb

https://www.rubydoc.info/gems/mysql_binlog/0.2.0/MysqlBinlog/BinlogStreamReader

https://github.com/jeremycole/mysql_binlog/blob/ac425f6688b523f016725dab8af3a708655c8a68/lib/mysql_binlog/reader/binlog_stream_reader.rb

https://github.com/xiongbill/mysql_binlog/blob/master/bin/mysql_binlog_dump

https://www.rubydoc.info/gems/mysql_binlog/0.3.2/MysqlBinlog/BinlogStreamReader

https://ruby-doc.org/stdlib-3.0.0/libdoc/socket/rdoc/Socket.html

https://www.google.com/search?channel=fs&client=ubuntu&q=ruby+mysql2+COM_BINLOG_DUMP

https://github.com/tmtm/ruby-mysql/blob/44520a12fac454a41a3759256f42fea04f0032d3/lib/mysql/protocol.rb

https://dev.mysql.com/doc/internals/en/com-binlog-dump-gtid.html

https://dev.mysql.com/doc/internals/en/com-binlog-dump.html

https://stackoverflow.com/questions/66567796/how-can-i-send-commandslike-com-register-slave-or-com-binlog-dump-to-the-mysql

https://dev.mysql.com/doc/c-api/8.0/en/mysql-binlog-fetch.html

https://github.com/brianmario/mysql2/blob/master/lib/mysql2/client.rb

https://www.rubydoc.info/gems/mysql_binlog/0.2.0/MysqlBinlog/BinlogStreamReader

https://www.rubydoc.info/gems/ruby-mysql/2.9.14/Mysql

https://github.com/noplay/python-mysql-replication

https://github.com/SponsorPay/ruby-binlog/blob/master/ext/ruby_binlog_event.h

https://github.com/SponsorPay/ruby-binlog/blob/master/ext/ruby_binlog_event.h

https://github.com/jeremycole/mysql_binlog

https://github.com/y310/kodama

https://github.com/SponsorPay/ruby-binlog/blob/master/ext/ruby_binlog.cpp

https://github.com/zalora/binlog-parser

https://github.com/twingly/ecco

https://github.com/jeremycole/mysql_binlog/blob/master/lib/mysql_binlog/reader/binlog_file_reader.rb

http://shlomi-noach.github.io/awesome-mysql/

https://github.com/brianmario/mysql2

https://github.com/brianmario/mysql2/blob/a825ba14af8c6def7d17d7562cc554db22043bd3/spec/mysql2/statement_spec.rb

https://github.com/brianmario/mysql2/blob/926f85382b0e6e8b051531e77f373cfbcea7365c/README.md

https://github.com/brianmario/mysql2/blob/b439a895ef6b289e1bc5e07303fc3952713fb948/lib/mysql2.rb

https://github.com/brianmario/mysql2/blob/7f4e844fccf6afa888d0bd108d4707a2a7784484/ext/mysql2/client.c

https://github.com/brianmario/mysql2/issues/771

https://github.com/jeremycole/mysql_binlog/commit/1f473eb77eb4cce709510de7c7bee73ba006a007

https://github.com/google/mysql/blob/master/client/mysqlbinlog.cc

https://github.com/tmtm/ruby-mysql/issues/5

https://www.rubydoc.info/gems/ruby-mysql-ext/2.9.11/Mysql/Protocol

https://www.google.com/search?channel=fs&client=ubuntu&q=binlog_api.h+mysql

https://github.com/Flipkart/MySQL-replication-listener/blob/master/include/binlog_api.h

https://dev.mysql.com/doc/refman/5.7/en/mysqlbinlog.html#option_mysqlbinlog_start-datetime

http://manpages.ubuntu.com/manpages/focal/man1/mysqlbinlog.1.html

https://github.com/tmtm/ruby-mysql/blob/master/lib/mysql/protocol.rb

https://github.com/jeremycole/mysql_binlog/blob/master/lib/mysql_binlog/reader/binlog_file_reader.rb

https://github.com/krowinski/php-mysql-replication

https://github.com/shyiko/mysql-binlog-connector-java/blob/dd710a5466381faa57442977b24fceff56a0820e/src/main/java/com/github/shyiko/mysql/binlog/event/deserialization/EventDeserializer.java

https://github.com/shyiko/mysql-binlog-connector-java/blob/dd710a5466381faa57442977b24fceff56a0820e/src/main/java/com/github/shyiko/mysql/binlog/io/ByteArrayInputStream.java

https://github.com/jeremycole/mysql_binlog

https://dev.mysql.com/doc/refman/5.7/en/replication-options-binary-log.html

https://github.com/mavenlink/changestream/blob/8c362a6609524e01a8dd370e38441b86e07e0814/docs/binlog-event-routing.md

https://github.com/ruby/ruby/blob/5e7675d442d968825fec100b915905a7706c981f/io.c#L6426
