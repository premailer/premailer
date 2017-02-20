require File.expand_path(File.dirname(__FILE__)) + '/helper'

class TestAdapter < Premailer::TestCase

  def test_default
    require 'nokogiri'
    assert_equal :nokogiri, Premailer::Adapter.default
  end

  def test_settable_via_use
    Premailer::Adapter.use = :nokogiri
    assert_equal 'Premailer::Adapter::Nokogiri', Premailer::Adapter.use.name
    Premailer::Adapter.use = :nokogiri_fast
    assert_equal 'Premailer::Adapter::NokogiriFast', Premailer::Adapter.use.name
    Premailer::Adapter.use = :nokogumbo
    assert_equal 'Premailer::Adapter::Nokogumbo', Premailer::Adapter.use.name
  end

  def test_adapters_are_findable_by_symbol
    assert_equal 'Premailer::Adapter::Nokogiri', Premailer::Adapter.find(:nokogiri).name
    assert_equal 'Premailer::Adapter::NokogiriFast', Premailer::Adapter.find(:nokogiri_fast).name
    assert_equal 'Premailer::Adapter::Nokogumbo', Premailer::Adapter.find(:nokogumbo).name
  end

  def test_adapters_are_findable_by_class
    assert_equal 'Premailer::Adapter::Nokogiri', Premailer::Adapter.find(Premailer::Adapter::Nokogiri).name
    assert_equal 'Premailer::Adapter::NokogiriFast', Premailer::Adapter.find(Premailer::Adapter::NokogiriFast).name
    assert_equal 'Premailer::Adapter::Nokogumbo', Premailer::Adapter.find(Premailer::Adapter::Nokogumbo).name
  end

  def test_raises_argument_error
    assert_raises(ArgumentError, "Invalid adapter: unknown") {
      Premailer::Adapter.find(:unknown)
    }
  end

end
