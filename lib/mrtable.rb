# coding: utf-8

require "json"

module Mrtable
  class Table
    attr_reader :rows, :header_cols

    def initialize(header_cols, rows)
      @header_cols = header_cols
      @rows = rows
    end

    # ci: column index
    # @return new table
    def map_col_with_ci
      new_rows = @rows.map { |cols|
        new_cols = []
        cols.each_with_index { |col, ci|
          new_cols << yield(col, ci)
        }
        new_cols
      }

      new_header_cols = []
      @header_cols.each_with_index { |col, ci|
        new_header_cols << yield(col, ci)
      }

      Table.new new_header_cols, new_rows
    end

    def calc_maxlens
      num_cols = @rows[0].size
      maxlens = (0...num_cols).map { |ci|
        cols_at_ci = @rows.map { |cols| cols[ci] }
        if @header_cols
          cols_at_ci << @header_cols[ci]
        end
        cols_at_ci.map { |col|
          Mrtable.col_len(col)
        }.max
      }

      # compatibility for GFM
      min_len = 3
      maxlens.map { |len| [len, min_len].max }
    end
  end

  def self.int?(s)
    /^\-?[\d,]+$/ =~ s
  end

  def self.pad_col(col, maxlen)
    if int? col
      pad_left col, maxlen
    else
      pad_right col, maxlen
    end
  end

  def self.col_len(col)
    (0...col.size).inject(0) { |sum, i|
      sum + (hankaku?(col[i]) ? 1 : 2)
    }
  end

  def self.pad_right(s, n)
    rest = n - col_len(s)
    if rest <= 0
      return s
    end
    s + (" " * rest)
  end

  def self.pad_left(s, n)
    rest = n - col_len(s)
    if rest <= 0
      return s
    end
    (" " * rest) + s
  end

  def self.serealize_col(col)
    if col.nil?
      return ""
    elsif col == ""
      return '""'
    end

    ret = json_encode(col)
    if /^\s+/ =~ ret || /\s+$/ =~ ret || /^\-+$/ =~ ret
      ret = '"' + ret + '"'
    end

    ret.gsub("|", "\\|")
  end

  def self.to_table_row(cols)
    "| " + cols.join(" | ") + " |"
  end

  # 32-126(0x20-0x7E), 65377-65439(0xFF61-0xFF9F)
  def self.hankaku?(c)
    (/^[ -~｡-ﾟ]$/ =~ c) ? true : false
  end

  def self.json_encode(val)
    json = JSON.generate([val])
    if /^\["(.*)"\]$/ =~ json
      $1
    elsif /^\[(.+)\]$/ =~ json
      $1
    else
      json
    end
  end

  def self.json_decode(str)
    if /^".*"$/ =~ str
      JSON.parse('[' + str + ']')[0]
    else
      JSON.parse('["' + str + '"]')[0]
    end
  end

  def self.parse_col(col)
    if col == ''
      nil
    elsif col == '""'
      ""
    else
      json_decode(col)
    end
  end

  def self.split_row(line)
    line2 = line + " "
    cols = []
    buf = ""
    pos = 2
    pos_delta = nil

    num_repeat_max = line2.size
    num_repeat_max.times do
      break if pos >= line2.size
      pos_delta = 1
      rest = line2[pos..-1]
      if /^ \| / =~ rest
        cols << buf; buf = ""
        pos_delta = 3
      elsif /^\\/ =~ rest
        if rest[1] == "|"
          buf += rest[1]
          pos_delta = 2
        else
          buf += rest[0..1]
          pos_delta = 2
        end
      else
        buf += rest[0]
      end
      pos += pos_delta
    end

    cols
  end

  def self.parse(text)
    lines = text.split(/\r?\n/)
    lines2 = lines.reject { |line|
      /^\s*$/ =~ line ||
      /^\| \-\-\-+ \|/ =~ line
    }
    rows = lines2.map { |line|
      split_row(line)
    }
    raw = Table.new rows[0], rows[1..-1]

    stripped = raw.map_col_with_ci { |col, _|
      col.strip
    }

    parsed = stripped.map_col_with_ci { |col, _|
      parse_col col
    }

    {
      :header_cols => parsed.header_cols,
      :rows => parsed.rows
    }
  end
  
  def self.generate(header_cols, rows)
    table = Table.new(header_cols, rows)

    serealized = table.map_col_with_ci { |col, _|
      serealize_col col
    }

    maxlens = serealized.calc_maxlens()

    padded = serealized.map_col_with_ci { |col, ci|
      pad_col col, maxlens[ci]
    }

    lines = []
    lines << to_table_row(padded.header_cols)
    lines << to_table_row(maxlens.map { |len| "-" * len })
    lines += padded.rows.map { |cols|
      to_table_row(cols)
    }
    lines.map { |line| line + "\n" }.join("")
  end
end
