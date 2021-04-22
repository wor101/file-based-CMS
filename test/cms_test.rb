ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'rack/test'


require_relative '../cms'

class CMSTest < MiniTest::Test
  include Rack::Test::Methods
  
  def app 
    Sinatra::Application
  end
  
  def test_index
    get '/'
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "about.txt")
    assert_includes(last_response.body, "changes.txt")
    assert_includes(last_response.body, "history.txt")
    assert_includes(last_response.body, "markdown_test.md")
  end  

  def test_content
    get '/about.txt'
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "The lich is, perhaps, the single most powerful form of undead known to exist.")
  end
  
  def test_no_file
    get '/dragon.txt'
    assert_equal(302, last_response.status)
    
    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "dragon.txt does not exist.")
  end
  
  def test_markdown_file
    get '/markdown_test.md'
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "<h1>h1 Heading 8-)</h1>")
    
  end
  
end