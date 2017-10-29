require 'test_helper'

class MrtableTest < Minitest::Test
  def test_serealize_col
    assert_equal '" \\| "', Mrtable.serealize_col(" | ")
  end
end
