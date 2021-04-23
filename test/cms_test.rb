ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'


require_relative '../cms'





class CMSTest < MiniTest::Test
  include Rack::Test::Methods
  
  def app 
    Sinatra::Application
  end
  
  def setup
  FileUtils.mkdir_p(data_path)
  end
  
  def teardown
  FileUtils.rm_rf(data_path)
  end
  
  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end
  
  def test_index
    create_document("about.txt")
    create_document("changes.txt")
    create_document("history.txt")
    create_document("markdown_test.md")
    
    get '/'
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "about.txt")
    assert_includes(last_response.body, "changes.txt")
    assert_includes(last_response.body, "history.txt")
    assert_includes(last_response.body, "markdown_test.md")
  end  

  def test_content
    create_document("about.txt", "Lich party time!")
    
    get '/about.txt'
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "Lich party time!")
  end
  
  def test_no_file
    get '/dragon.txt'
    assert_equal(302, last_response.status)
    
    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "dragon.txt does not exist.")
  end
  
  def test_markdown_file
    create_document("markdown_test.md", "<h1>h1 Heading 8-)</h1>")
    
    get '/markdown_test.md'
    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "<h1>h1 Heading 8-)</h1>")
  end
  
  def test_edit_file_content
    create_document("changes.txt")
    
    post '/changes.txt/update', edit_content: 'New pahty content'
    assert_equal(302, last_response.status)
    
    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'changes.txt has been updated.')
    
    get '/changes.txt'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'New pahty content')
  end
  
end