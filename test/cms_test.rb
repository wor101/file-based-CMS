ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'rack/test'


require_relative 'cms'

class CmsTest < MiniTest::Test
  
end