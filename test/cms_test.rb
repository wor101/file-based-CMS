ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'
require 'bcrypt'

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
  
  def session
    last_request.env["rack.session"]
  end
  
  def admin_session
    { "rack.session" => { username: "admin" } }
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

    assert_equal("dragon.txt does not exist.", session[:message])

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

    post '/changes.txt/update', {edit_content: 'New pahty content'}, admin_session
    assert_equal(302, last_response.status)
    assert_equal('changes.txt has been updated.', session[:message])

    get '/changes.txt'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'New pahty content')
  end
  
  def test_new_document
    get '/new_document', {}, admin_session
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Add a new document:')
  end
  
  def test_add_document_without_name
    post '/new_document', {name_document: ''}, admin_session
    
    assert_equal(302, last_response.status)
    assert_equal("A name is required.", session[:message])
  end
  
  def test_add_document_with_invalid_file_type
    post '/new_document', {name_document: 'no_file_type'}, admin_session
    
    assert_equal(302, last_response.status)
    assert_equal("File name must end in .txt or .md", session[:message])
  end
  
  def test_add_valid_document
    post '/new_document', {name_document: 'valid_doc.md'}, admin_session
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, ">valid_doc.md </a>")
  end
  
  def test_delete
    create_document("doc_to_delete.md")

    post 'doc_to_delete.md/delete', {}, admin_session
    assert_equal(302, last_response.status)
    assert_equal("doc_to_delete.md has been deleted.", session[:message])

    get '/'
    refute_includes(last_response.body, %q(href="doc_to_delete.md"))
  end
  
  def test_sign_in_button
    get '/users/signin'
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Username:')
  end
  
  def test_signin_bad_credentials
    post '/users/signin', username: 'bad_user', password: 'bad_pass'
    assert_equal(422, last_response.status)
    assert_nil(session[:username])
    assert_includes(last_response.body, 'Invalid Credentials')
  end
  
  def test_signin_good_credentials
    post '/users/signin', username: 'admin', password: 'secret'
    assert_equal(302, last_response.status)
    assert_equal("Welcome!", session[:message])
    assert_equal("admin", session[:username])
    
    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "Signed in as admin")
  end
  
  def test_signout
    post '/users/signin', username: 'admin', password: 'secret'
    get last_response["Location"]
    assert_includes(last_response.body, "Welcome")
    
    get '/users/signout'
    assert_equal(302, last_response.status)
    assert_equal("You have been signed out.", session[:message])
    get last_response["Location"]
    assert_nil(session[:username])
    assert_includes(last_response.body, "Sign In")
  end
  
  def test_visit_edit_page_when_signed_out
    create_document('test_doc.txt')
    
    get '/test_doc.txt/edit'
    assert_equal(302, last_response.status)
    assert_equal("You must be signed in to do that.", session[:message])
  end
  
  def test_udpate_document_when_signed_out
    create_document('test_doc.txt')
    
    post '/test_doc.txt/update', edit_content: 'New pahty content'
    assert_equal(302, last_response.status)
    assert_equal("You must be signed in to do that.", session[:message])
  end
  
  def test_visit_new_document_when_signed_out
    get '/new_document'
    assert_equal(302, last_response.status)
    assert_equal("You must be signed in to do that.", session[:message])
  end
  
  def test_create_new_document_when_signed_out
    post '/new_document', name_document: 'test_doc.txt'
    assert_equal(302, last_response.status)
    assert_equal("You must be signed in to do that.", session[:message])  
  end
  
  def test_delete_document_when_signed_out
    create_document('test_doc.txt')
    
    post 'test_doc.txt/delete'
    assert_equal(302, last_response.status)
    assert_equal("You must be signed in to do that.", session[:message])  
  end
  
  def test_load_users
    users = load_users

    assert_includes(users.keys, "Morgar")
  end
  
  def test_duplicate_file
    create_document("test_doc.txt")
    
    post 'test_doc.txt/duplicate'
    assert_equal(302, last_response.status)
    assert_equal("Duplicate of test_doc.txt has been created.", session[:message])
    
    get last_response["Location"]
    assert_includes(last_response.body, "copy_test_doc.txt")
  end
  
end