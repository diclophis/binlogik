#

###################################################################
#NOTE: include any stdlib first
###################################################################
require 'bigdecimal'
require 'open3'
require 'stringio'
require 'json'
require 'securerandom'
require 'digest'
require 'fcntl'
require 'fileutils'
require 'forwardable'
# ...


###################################################################
#NOTE: then bundler/gem dependencies next, after bundler/setup
require "rubygems"
require "bundler/setup"
require 'mysql2'
require 'superconfig2'
# ...


#NOTE: this way we can ensure the proper libs are loaded
#NOTE: all other internalized depedencies autoloaded below
module Mysql2BinlogStream
  class Error < StandardError; end

  autoload 'Config', 'mysql2_binlog_stream/config'
  autoload 'Stream', 'mysql2_binlog_stream/stream'
  autoload 'Cli', 'mysql2_binlog_stream/cli'
  autoload 'App', 'mysql2_binlog_stream/app'
  autoload 'BinlogReader', 'mysql2_binlog_stream/binlog_reader'
  autoload 'BinlogFieldParser', 'mysql2_binlog_stream/binlog_field_parser'
  autoload 'BinlogEventParser', 'mysql2_binlog_stream/binlog_event_parser'
  autoload 'Binlog', 'mysql2_binlog_stream/binlog'
  autoload 'Observability', 'mysql2_binlog_stream/observability'
  autoload 'Cursor', 'mysql2_binlog_stream/cursor'
  autoload 'Fetcher', 'mysql2_binlog_stream/fetcher'

  #TODO: maybe build this at CD/CI time???
  #NOTE: this should be updated
  # A hash to map MySQL collation name to ID and character set name.
  #
  # This hash is produced by the following query:
  #   SELECT concat(
  #     "    :",
  #     rpad(collation_name, 24, " "),
  #     " => { :id => ",
  #     lpad(id, 3, " "),
  #     ", :character_set => :",
  #     rpad(character_set_name, 8, " "),
  #     " },"
  #   ) AS ruby_code
  #   FROM information_schema.collations
  #   ORDER BY collation_name
  #
  COLLATION_HASH = {
    :armscii8_bin             => { :id =>  64, :character_set => :armscii8 },
    :armscii8_general_ci      => { :id =>  32, :character_set => :armscii8 },
    :ascii_bin                => { :id =>  65, :character_set => :ascii    },
    :ascii_general_ci         => { :id =>  11, :character_set => :ascii    },
    :big5_bin                 => { :id =>  84, :character_set => :big5     },
    :big5_chinese_ci          => { :id =>   1, :character_set => :big5     },
    :binary                   => { :id =>  63, :character_set => :binary   },
    :cp1250_bin               => { :id =>  66, :character_set => :cp1250   },
    :cp1250_croatian_ci       => { :id =>  44, :character_set => :cp1250   },
    :cp1250_czech_cs          => { :id =>  34, :character_set => :cp1250   },
    :cp1250_general_ci        => { :id =>  26, :character_set => :cp1250   },
    :cp1250_polish_ci         => { :id =>  99, :character_set => :cp1250   },
    :cp1251_bin               => { :id =>  50, :character_set => :cp1251   },
    :cp1251_bulgarian_ci      => { :id =>  14, :character_set => :cp1251   },
    :cp1251_general_ci        => { :id =>  51, :character_set => :cp1251   },
    :cp1251_general_cs        => { :id =>  52, :character_set => :cp1251   },
    :cp1251_ukrainian_ci      => { :id =>  23, :character_set => :cp1251   },
    :cp1256_bin               => { :id =>  67, :character_set => :cp1256   },
    :cp1256_general_ci        => { :id =>  57, :character_set => :cp1256   },
    :cp1257_bin               => { :id =>  58, :character_set => :cp1257   },
    :cp1257_general_ci        => { :id =>  59, :character_set => :cp1257   },
    :cp1257_lithuanian_ci     => { :id =>  29, :character_set => :cp1257   },
    :cp850_bin                => { :id =>  80, :character_set => :cp850    },
    :cp850_general_ci         => { :id =>   4, :character_set => :cp850    },
    :cp852_bin                => { :id =>  81, :character_set => :cp852    },
    :cp852_general_ci         => { :id =>  40, :character_set => :cp852    },
    :cp866_bin                => { :id =>  68, :character_set => :cp866    },
    :cp866_general_ci         => { :id =>  36, :character_set => :cp866    },
    :cp932_bin                => { :id =>  96, :character_set => :cp932    },
    :cp932_japanese_ci        => { :id =>  95, :character_set => :cp932    },
    :dec8_bin                 => { :id =>  69, :character_set => :dec8     },
    :dec8_swedish_ci          => { :id =>   3, :character_set => :dec8     },
    :eucjpms_bin              => { :id =>  98, :character_set => :eucjpms  },
    :eucjpms_japanese_ci      => { :id =>  97, :character_set => :eucjpms  },
    :euckr_bin                => { :id =>  85, :character_set => :euckr    },
    :euckr_korean_ci          => { :id =>  19, :character_set => :euckr    },
    :gb2312_bin               => { :id =>  86, :character_set => :gb2312   },
    :gb2312_chinese_ci        => { :id =>  24, :character_set => :gb2312   },
    :gbk_bin                  => { :id =>  87, :character_set => :gbk      },
    :gbk_chinese_ci           => { :id =>  28, :character_set => :gbk      },
    :geostd8_bin              => { :id =>  93, :character_set => :geostd8  },
    :geostd8_general_ci       => { :id =>  92, :character_set => :geostd8  },
    :greek_bin                => { :id =>  70, :character_set => :greek    },
    :greek_general_ci         => { :id =>  25, :character_set => :greek    },
    :hebrew_bin               => { :id =>  71, :character_set => :hebrew   },
    :hebrew_general_ci        => { :id =>  16, :character_set => :hebrew   },
    :hp8_bin                  => { :id =>  72, :character_set => :hp8      },
    :hp8_english_ci           => { :id =>   6, :character_set => :hp8      },
    :keybcs2_bin              => { :id =>  73, :character_set => :keybcs2  },
    :keybcs2_general_ci       => { :id =>  37, :character_set => :keybcs2  },
    :koi8r_bin                => { :id =>  74, :character_set => :koi8r    },
    :koi8r_general_ci         => { :id =>   7, :character_set => :koi8r    },
    :koi8u_bin                => { :id =>  75, :character_set => :koi8u    },
    :koi8u_general_ci         => { :id =>  22, :character_set => :koi8u    },
    :latin1_bin               => { :id =>  47, :character_set => :latin1   },
    :latin1_danish_ci         => { :id =>  15, :character_set => :latin1   },
    :latin1_general_ci        => { :id =>  48, :character_set => :latin1   },
    :latin1_general_cs        => { :id =>  49, :character_set => :latin1   },
    :latin1_german1_ci        => { :id =>   5, :character_set => :latin1   },
    :latin1_german2_ci        => { :id =>  31, :character_set => :latin1   },
    :latin1_spanish_ci        => { :id =>  94, :character_set => :latin1   },
    :latin1_swedish_ci        => { :id =>   8, :character_set => :latin1   },
    :latin2_bin               => { :id =>  77, :character_set => :latin2   },
    :latin2_croatian_ci       => { :id =>  27, :character_set => :latin2   },
    :latin2_czech_cs          => { :id =>   2, :character_set => :latin2   },
    :latin2_general_ci        => { :id =>   9, :character_set => :latin2   },
    :latin2_hungarian_ci      => { :id =>  21, :character_set => :latin2   },
    :latin5_bin               => { :id =>  78, :character_set => :latin5   },
    :latin5_turkish_ci        => { :id =>  30, :character_set => :latin5   },
    :latin7_bin               => { :id =>  79, :character_set => :latin7   },
    :latin7_estonian_cs       => { :id =>  20, :character_set => :latin7   },
    :latin7_general_ci        => { :id =>  41, :character_set => :latin7   },
    :latin7_general_cs        => { :id =>  42, :character_set => :latin7   },
    :macce_bin                => { :id =>  43, :character_set => :macce    },
    :macce_general_ci         => { :id =>  38, :character_set => :macce    },
    :macroman_bin             => { :id =>  53, :character_set => :macroman },
    :macroman_general_ci      => { :id =>  39, :character_set => :macroman },
    :sjis_bin                 => { :id =>  88, :character_set => :sjis     },
    :sjis_japanese_ci         => { :id =>  13, :character_set => :sjis     },
    :swe7_bin                 => { :id =>  82, :character_set => :swe7     },
    :swe7_swedish_ci          => { :id =>  10, :character_set => :swe7     },
    :tis620_bin               => { :id =>  89, :character_set => :tis620   },
    :tis620_thai_ci           => { :id =>  18, :character_set => :tis620   },
    :ucs2_bin                 => { :id =>  90, :character_set => :ucs2     },
    :ucs2_czech_ci            => { :id => 138, :character_set => :ucs2     },
    :ucs2_danish_ci           => { :id => 139, :character_set => :ucs2     },
    :ucs2_esperanto_ci        => { :id => 145, :character_set => :ucs2     },
    :ucs2_estonian_ci         => { :id => 134, :character_set => :ucs2     },
    :ucs2_general_ci          => { :id =>  35, :character_set => :ucs2     },
    :ucs2_general_mysql500_ci => { :id => 159, :character_set => :ucs2     },
    :ucs2_hungarian_ci        => { :id => 146, :character_set => :ucs2     },
    :ucs2_icelandic_ci        => { :id => 129, :character_set => :ucs2     },
    :ucs2_latvian_ci          => { :id => 130, :character_set => :ucs2     },
    :ucs2_lithuanian_ci       => { :id => 140, :character_set => :ucs2     },
    :ucs2_persian_ci          => { :id => 144, :character_set => :ucs2     },
    :ucs2_polish_ci           => { :id => 133, :character_set => :ucs2     },
    :ucs2_romanian_ci         => { :id => 131, :character_set => :ucs2     },
    :ucs2_roman_ci            => { :id => 143, :character_set => :ucs2     },
    :ucs2_sinhala_ci          => { :id => 147, :character_set => :ucs2     },
    :ucs2_slovak_ci           => { :id => 141, :character_set => :ucs2     },
    :ucs2_slovenian_ci        => { :id => 132, :character_set => :ucs2     },
    :ucs2_spanish2_ci         => { :id => 142, :character_set => :ucs2     },
    :ucs2_spanish_ci          => { :id => 135, :character_set => :ucs2     },
    :ucs2_swedish_ci          => { :id => 136, :character_set => :ucs2     },
    :ucs2_turkish_ci          => { :id => 137, :character_set => :ucs2     },
    :ucs2_unicode_ci          => { :id => 128, :character_set => :ucs2     },
    :ujis_bin                 => { :id =>  91, :character_set => :ujis     },
    :ujis_japanese_ci         => { :id =>  12, :character_set => :ujis     },
    :utf16_bin                => { :id =>  55, :character_set => :utf16    },
    :utf16_czech_ci           => { :id => 111, :character_set => :utf16    },
    :utf16_danish_ci          => { :id => 112, :character_set => :utf16    },
    :utf16_esperanto_ci       => { :id => 118, :character_set => :utf16    },
    :utf16_estonian_ci        => { :id => 107, :character_set => :utf16    },
    :utf16_general_ci         => { :id =>  54, :character_set => :utf16    },
    :utf16_hungarian_ci       => { :id => 119, :character_set => :utf16    },
    :utf16_icelandic_ci       => { :id => 102, :character_set => :utf16    },
    :utf16_latvian_ci         => { :id => 103, :character_set => :utf16    },
    :utf16_lithuanian_ci      => { :id => 113, :character_set => :utf16    },
    :utf16_persian_ci         => { :id => 117, :character_set => :utf16    },
    :utf16_polish_ci          => { :id => 106, :character_set => :utf16    },
    :utf16_romanian_ci        => { :id => 104, :character_set => :utf16    },
    :utf16_roman_ci           => { :id => 116, :character_set => :utf16    },
    :utf16_sinhala_ci         => { :id => 120, :character_set => :utf16    },
    :utf16_slovak_ci          => { :id => 114, :character_set => :utf16    },
    :utf16_slovenian_ci       => { :id => 105, :character_set => :utf16    },
    :utf16_spanish2_ci        => { :id => 115, :character_set => :utf16    },
    :utf16_spanish_ci         => { :id => 108, :character_set => :utf16    },
    :utf16_swedish_ci         => { :id => 109, :character_set => :utf16    },
    :utf16_turkish_ci         => { :id => 110, :character_set => :utf16    },
    :utf16_unicode_ci         => { :id => 101, :character_set => :utf16    },
    :utf32_bin                => { :id =>  61, :character_set => :utf32    },
    :utf32_czech_ci           => { :id => 170, :character_set => :utf32    },
    :utf32_danish_ci          => { :id => 171, :character_set => :utf32    },
    :utf32_esperanto_ci       => { :id => 177, :character_set => :utf32    },
    :utf32_estonian_ci        => { :id => 166, :character_set => :utf32    },
    :utf32_general_ci         => { :id =>  60, :character_set => :utf32    },
    :utf32_hungarian_ci       => { :id => 178, :character_set => :utf32    },
    :utf32_icelandic_ci       => { :id => 161, :character_set => :utf32    },
    :utf32_latvian_ci         => { :id => 162, :character_set => :utf32    },
    :utf32_lithuanian_ci      => { :id => 172, :character_set => :utf32    },
    :utf32_persian_ci         => { :id => 176, :character_set => :utf32    },
    :utf32_polish_ci          => { :id => 165, :character_set => :utf32    },
    :utf32_romanian_ci        => { :id => 163, :character_set => :utf32    },
    :utf32_roman_ci           => { :id => 175, :character_set => :utf32    },
    :utf32_sinhala_ci         => { :id => 179, :character_set => :utf32    },
    :utf32_slovak_ci          => { :id => 173, :character_set => :utf32    },
    :utf32_slovenian_ci       => { :id => 164, :character_set => :utf32    },
    :utf32_spanish2_ci        => { :id => 174, :character_set => :utf32    },
    :utf32_spanish_ci         => { :id => 167, :character_set => :utf32    },
    :utf32_swedish_ci         => { :id => 168, :character_set => :utf32    },
    :utf32_turkish_ci         => { :id => 169, :character_set => :utf32    },
    :utf32_unicode_ci         => { :id => 160, :character_set => :utf32    },
    :utf8mb4_bin              => { :id =>  46, :character_set => :utf8mb4  },
    :utf8mb4_czech_ci         => { :id => 234, :character_set => :utf8mb4  },
    :utf8mb4_danish_ci        => { :id => 235, :character_set => :utf8mb4  },
    :utf8mb4_esperanto_ci     => { :id => 241, :character_set => :utf8mb4  },
    :utf8mb4_estonian_ci      => { :id => 230, :character_set => :utf8mb4  },
    :utf8mb4_general_ci       => { :id =>  45, :character_set => :utf8mb4  },
    :utf8mb4_hungarian_ci     => { :id => 242, :character_set => :utf8mb4  },
    :utf8mb4_icelandic_ci     => { :id => 225, :character_set => :utf8mb4  },
    :utf8mb4_latvian_ci       => { :id => 226, :character_set => :utf8mb4  },
    :utf8mb4_lithuanian_ci    => { :id => 236, :character_set => :utf8mb4  },
    :utf8mb4_persian_ci       => { :id => 240, :character_set => :utf8mb4  },
    :utf8mb4_polish_ci        => { :id => 229, :character_set => :utf8mb4  },
    :utf8mb4_romanian_ci      => { :id => 227, :character_set => :utf8mb4  },
    :utf8mb4_roman_ci         => { :id => 239, :character_set => :utf8mb4  },
    :utf8mb4_sinhala_ci       => { :id => 243, :character_set => :utf8mb4  },
    :utf8mb4_slovak_ci        => { :id => 237, :character_set => :utf8mb4  },
    :utf8mb4_slovenian_ci     => { :id => 228, :character_set => :utf8mb4  },
    :utf8mb4_spanish2_ci      => { :id => 238, :character_set => :utf8mb4  },
    :utf8mb4_spanish_ci       => { :id => 231, :character_set => :utf8mb4  },
    :utf8mb4_swedish_ci       => { :id => 232, :character_set => :utf8mb4  },
    :utf8mb4_turkish_ci       => { :id => 233, :character_set => :utf8mb4  },
    :utf8mb4_unicode_ci       => { :id => 224, :character_set => :utf8mb4  },
    :utf8_bin                 => { :id =>  83, :character_set => :utf8     },
    :utf8_czech_ci            => { :id => 202, :character_set => :utf8     },
    :utf8_danish_ci           => { :id => 203, :character_set => :utf8     },
    :utf8_esperanto_ci        => { :id => 209, :character_set => :utf8     },
    :utf8_estonian_ci         => { :id => 198, :character_set => :utf8     },
    :utf8_general_ci          => { :id =>  33, :character_set => :utf8     },
    :utf8_general_mysql500_ci => { :id => 223, :character_set => :utf8     },
    :utf8_hungarian_ci        => { :id => 210, :character_set => :utf8     },
    :utf8_icelandic_ci        => { :id => 193, :character_set => :utf8     },
    :utf8_latvian_ci          => { :id => 194, :character_set => :utf8     },
    :utf8_lithuanian_ci       => { :id => 204, :character_set => :utf8     },
    :utf8_persian_ci          => { :id => 208, :character_set => :utf8     },
    :utf8_polish_ci           => { :id => 197, :character_set => :utf8     },
    :utf8_romanian_ci         => { :id => 195, :character_set => :utf8     },
    :utf8_roman_ci            => { :id => 207, :character_set => :utf8     },
    :utf8_sinhala_ci          => { :id => 211, :character_set => :utf8     },
    :utf8_slovak_ci           => { :id => 205, :character_set => :utf8     },
    :utf8_slovenian_ci        => { :id => 196, :character_set => :utf8     },
    :utf8_spanish2_ci         => { :id => 206, :character_set => :utf8     },
    :utf8_spanish_ci          => { :id => 199, :character_set => :utf8     },
    :utf8_swedish_ci          => { :id => 200, :character_set => :utf8     },
    :utf8_turkish_ci          => { :id => 201, :character_set => :utf8     },
    :utf8_unicode_ci          => { :id => 192, :character_set => :utf8     },
  }

  # An array of collation IDs to collation and character set name for
  # efficient lookup by ID.
  COLLATION = COLLATION_HASH.inject(Array.new) do |collation_array, item|
    collation_array[item[1][:id]] = { 
      :character_set => item[1][:character_set],
      :collation     => item[0],
    }
    collation_array
  end

  #TODO: improve SUPERCONFIG/ENV interface!!?
  SUPERCONFIG = Config.new
end
