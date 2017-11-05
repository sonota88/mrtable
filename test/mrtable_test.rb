require 'test_helper'

class MrtableTest < Minitest::Test
  def test_serealize_col
    assert_equal '" \\| "', Mrtable.serealize_col(" | ")
  end

  def test_complement_header_cols
    text = <<~EOB
    | a |
    | 1 | 2 | 3 |
    EOB

    data = Mrtable.parse(text, :complement => "N/A")

    assert_equal '["a", "N/A", "N/A"]', data[:header_cols].inspect
  end

  def test_complement_cols
    text = <<~EOB
    | a | b | c |
    | 1 |
    EOB

    data = Mrtable.parse(text, :complement => "N/A")

    assert_equal '["1", "N/A", "N/A"]', data[:rows][0].inspect
  end
end
