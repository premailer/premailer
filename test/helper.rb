# frozen_string_literal: true
require 'bundler/setup'
require 'maxitest/autorun'
require 'webmock/minitest'
require 'premailer'

class Premailer
  class TestCase < Minitest::Test
    BASE_URI  = 'http://premailer.dev/'
    BASE_PATH = __dir__ + '/files'

    def setup
      stub_request(:any, /premailer\.dev\/*/).to_return do |request|
        file_path = BASE_PATH + Addressable::URI.parse(request.uri).path
        if File.exist?(file_path)
          { :status => 200, :body => File.open(file_path) }
        else
          { :status => 404, :body => "#{file_path} not found" }
        end
      end

      stub_request(:get, /my\.example\.com:8080\/*/).to_return(:status => 200, :body => "", :headers => {})
    end

    def default_test; end

    protected

    def local_setup(f = 'base.html', opts = {})
      base_file = BASE_PATH + '/' + f
      premailer = Premailer.new(base_file, opts)
      premailer.to_inline_css
      @doc = premailer.processed_doc
    end

    def remote_setup(f = 'base.html', opts = {})
      @premailer = Premailer.new(BASE_URI + f.to_s, opts)
      @premailer.to_inline_css
      @doc = @premailer.processed_doc
    end
  end
end
