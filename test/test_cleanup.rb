# frozen_string_literal: true
require __dir__ + '/helper'

class TestCleanup < Premailer::TestCase
  def test_cleanup_nils_out_instance_variables
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      pm = Premailer.new('<p>test</p>', :with_html_string => true, :adapter => adapter)
      pm.to_inline_css
      pm.cleanup!

      assert_nil pm.doc, "Using: #{adapter}"
      assert_nil pm.processed_doc, "Using: #{adapter}"
      assert_nil pm.unmergable_rules, "Using: #{adapter}"
    end
  end

  def test_cleanup_can_be_called_twice
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      pm = Premailer.new('<p>test</p>', :with_html_string => true, :adapter => adapter)
      pm.to_inline_css
      pm.cleanup!
      pm.cleanup!

      assert_nil pm.doc, "Using: #{adapter}"
      assert_nil pm.processed_doc, "Using: #{adapter}"
    end
  end

  def test_cleanup_before_processing
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      pm = Premailer.new('<p>test</p>', :with_html_string => true, :adapter => adapter)
      pm.cleanup!

      assert_nil pm.doc, "Using: #{adapter}"
      assert_nil pm.processed_doc, "Using: #{adapter}"
    end
  end

  def test_output_is_usable_after_cleanup
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      pm = Premailer.new('<p>test</p>', :with_html_string => true, :adapter => adapter)
      result = pm.to_inline_css
      pm.cleanup!

      assert_match /test/, result, "Using: #{adapter}"
    end
  end
end
