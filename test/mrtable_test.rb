require 'test_helper'

class MrtableTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Mrtable::VERSION
  end

  def test_serealize_col
    assert_equal '" \\| "', Mrtable.serealize_col(" | ")
  end
end
