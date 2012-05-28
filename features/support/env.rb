require "bundler/setup"
require 'aruba/cucumber'
require 'clipboard'
require 'securerandom'
require 'fileutils'
require_relative '../../lib/pws'

# Make sure bin is available

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"

# Hooks

BEGIN{
  $original_pws_file = ENV["PWS"]
}

END{
  Clipboard.clear
  ENV["PWS"] = $original_pws_file
  FileUtils.rm Dir['pws-test-*']
}

Around do |_, block|
  # NOTE: You cannot parallelize the tests, because they use the clipboard and the env vars...
  Clipboard.clear
  ENV["PWS"] = File.expand_path('pws-test-' + SecureRandom.uuid)
  
  block.call
  
  FileUtils.rm ENV["PWS"] if File.exist? ENV["PWS"]
end

# Hacks

Before('@slow-hack') do
  @aruba_io_wait_seconds = 0.5
end

Before('@very-slow-hack') do
  @aruba_io_wait_seconds = 7
end

Before('@wait-11s') do
  @aruba_timeout_seconds = 14
end
