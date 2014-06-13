#UTF-8

require 'minitest/autorun'

class TestR < MiniTest::Unit::TestCase
  
  def test_simple
    a = "a"
    assert_equal("a", a)
  end
end

