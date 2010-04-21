$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'metacircus'
require 'rspec'
require 'rspec/autorun'
require 'pp'
require 'rr'

Rspec.configure do |config|
  config.mock_with :rr

  # If you'd prefer not to run each of your examples within a transaction,
  # uncomment the following line.
  # config.use_transactional_examples false
end
