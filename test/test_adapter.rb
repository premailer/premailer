require File.expand_path(File.dirname(__FILE__)) + '/helper'

class TestAdapter < Premailer::TestCase

  def test_default_to_best_available
    require 'nokogiri'
    assert_equal 'Premailer::Adapter::Nokogiri', Premailer::Adapter.use.name
  end

  def test_settable_via_symbol
    Premailer::Adapter.use = :hpricot
    assert_equal 'Premailer::Adapter::Hpricot', Premailer::Adapter.use.name
  end

  def test_settable_via_symbol2
    Premailer::Adapter.use = :nokogumbo
    assert_equal 'Premailer::Adapter::Nokogumbo', Premailer::Adapter.use.name
  end

  def test_adapters_are_findable_by_symbol
    assert_equal 'Premailer::Adapter::Hpricot', Premailer::Adapter.find(:hpricot).name
    assert_equal 'Premailer::Adapter::Nokogiri', Premailer::Adapter.find(:nokogiri).name
    assert_equal 'Premailer::Adapter::Nokogumbo', Premailer::Adapter.find(:nokogumbo).name
  end

  def test_adapters_are_findable_by_class
    assert_equal 'Premailer::Adapter::Hpricot', Premailer::Adapter.find(Premailer::Adapter::Hpricot).name
    assert_equal 'Premailer::Adapter::Nokogiri', Premailer::Adapter.find(Premailer::Adapter::Nokogiri).name
    assert_equal 'Premailer::Adapter::Nokogumbo', Premailer::Adapter.find(Premailer::Adapter::Nokogumbo).name
  end

  def test_raises_argument_error
    assert_raises(ArgumentError, "Invalid adapter: unknown") {
      Premailer::Adapter.find(:unknown)
    }
  end

end
