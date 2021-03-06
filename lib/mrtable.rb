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
      new_rows = @rows.map do |cols|
        new_cols = []
        cols.each_with_index { |col, ci|
          new_cols << yield(col, ci)
        }
        new_cols
      end

      new_header_cols = []
      @header_cols.each_with_index { |col, ci|
        new_header_cols << yield(col, ci)
      }

      Table.new new_header_cols, new_rows
    end

    def calc_maxlens
      num_cols = @rows[0].size
      maxlens = (0...num_cols).map do |ci|
        cols_at_ci = @rows.map { |cols| cols[ci] }
        if @header_cols
          cols_at_ci << @header_cols[ci]
        end
        cols_at_ci
          .map { |col| Mrtable.col_len(col) }
          .max
      end

      # compatibility for GFM
      min_len = 3
      maxlens.map { |len| [len, min_len].max }
    end

    def complement(val)
      num_cols_max = [
        @header_cols.size,
        @rows.map { |cols| cols.size }.max
      ].max

      new_header_cols = Mrtable.complement_cols(
        @header_cols, num_cols_max, val)

      new_rows = @rows.map { |cols|
        Mrtable.complement_cols(cols, num_cols_max, val)
      }

      Table.new new_header_cols, new_rows
    end
  end

  def self.complement_cols(cols, num_cols_max, val)
    (0...num_cols_max).map do |ci|
      if ci < cols.size
        cols[ci]
      else
        val
      end
    end
  end

  def self.int?(s)
    /^\-?[\d,]+$/.match?(s)
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
    if rest == 0
      return s
    end
    s + (" " * rest)
  end

  def self.pad_left(s, n)
    rest = n - col_len(s)
    if rest == 0
      return s
    end
    (" " * rest) + s
  end

  def self.serialize_col(col)
    if col.nil?
      return ""
    elsif col == ""
      return '""'
    end

    ret = json_encode(col)
    if /^\s+/.match?(ret) or /\s+$/.match?(ret) or /^\-+$/.match?(ret)
      ret = '"' + ret + '"'
    end

    ret.gsub("|", "\\|")
  end

  def self.to_table_row(cols)
    "| " + cols.join(" | ") + " |"
  end

  # 32-126(0x20-0x7E), 65377-65439(0xFF61-0xFF9F)
  def self.hankaku?(c)
    /^[ -~｡-ﾟ]$/.match?(c)
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
    if /^".*"$/.match?(str)
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
    work_line = line + " "
    cols = []
    buf = ""
    pos = 2
    pos_delta = nil

    num_repeat_max = work_line.size
    num_repeat_max.times do
      break if pos >= work_line.size
      pos_delta = 1
      rest = work_line[pos..-1]
      if /^ \| /.match?(rest)
        cols << buf; buf = ""
        pos_delta = 3
      elsif /^\\/.match?(rest)
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

  def self.parse(text, opts = {})
    lines = text
      .split(/\r?\n/)
      .reject { |line|
        /^\s*$/.match?(line) or
        /^\| \-\-\-+ \|/.match?(line)
      }
    rows = lines.map { |line|
      split_row(line)
    }
    raw = Table.new rows[0], rows[1..-1]

    stripped = raw.map_col_with_ci { |col, _|
      col.strip
    }

    parsed = stripped.map_col_with_ci { |col, _|
      parse_col col
    }

    if opts.key? :complement
      unless opts[:complement].is_a? String or opts[:complement].nil?
        raise "opts[:complement] must be String or nil"
      end
      parsed = parsed.complement opts[:complement]
    end

    [
      parsed.header_cols,
      parsed.rows
    ]
  end

  def self.generate(header_cols, rows)
    table = Table.new(header_cols, rows)

    serialized = table.map_col_with_ci { |col, _|
      serialize_col col
    }

    maxlens = serialized.calc_maxlens()

    padded = serialized.map_col_with_ci { |col, ci|
      pad_col col, maxlens[ci]
    }

    lines = []
    lines << to_table_row(padded.header_cols)
    lines << to_table_row(maxlens.map { |len| "-" * len })
    lines += padded.rows.map { |cols|
      to_table_row(cols)
    }
    lines
      .map { |line| line + "\n" }
      .join("")
  end
end
