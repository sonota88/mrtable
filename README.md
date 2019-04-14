# Mrtable

Machine readable table.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mrtable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mrtable

## Example

```ruby
require 'pp'
require 'mrtable'

mrtable_text = <<'EOB'
| c1  | c2  | c3  | c4  |
| --- | --- | --- | --- |
| "123" | "abc" | "日本語" |    |
|  123  |  abc  |  日本語  |    |
| "" | " " | "  " |  |
| "\\\t\r\n\"" |  |  |  |
|  \\\t\r\n\"  |  |  |  |
| "a" | " a" | "a " | " a " |
|  a  |   a  |  a   |   a   |
| "\|" | "1 \| 2" |  |  |
|  \|  |  1 \| 2  |  |  |
| "null" | "NULL" |  |  |
|  null  |  NULL  |  |  |
EOB

header, rows = Mrtable.parse(mrtable_text)
pp header, rows

=begin

["c1", "c2", "c3", "c4"]
[["123", "abc", "日本語", nil],
 ["123", "abc", "日本語", nil],
 ["", " ", "  ", nil],
 ["\\\t\r\n" + "\"", nil, nil, nil],
 ["\\\t\r\n" + "\"", nil, nil, nil],
 ["a", " a", "a ", " a "],
 ["a", "a", "a", "a"],
 ["|", "1 | 2", nil, nil],
 ["|", "1 | 2", nil, nil],
 ["null", "NULL", nil, nil],
 ["null", "NULL", nil, nil]]

=end

puts Mrtable.generate(header, rows)

=begin

| c1         | c2     | c3     | c4    |
| ---------- | ------ | ------ | ----- |
|        123 | abc    | 日本語 |       |
|        123 | abc    | 日本語 |       |
| ""         | " "    | "  "   |       |
| \\\t\r\n\" |        |        |       |
| \\\t\r\n\" |        |        |       |
| a          | " a"   | "a "   | " a " |
| a          | a      | a      | a     |
| \|         | 1 \| 2 |        |       |
| \|         | 1 \| 2 |        |       |
| null       | NULL   |        |       |
| null       | NULL   |        |       |

=end
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
