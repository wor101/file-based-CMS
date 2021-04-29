require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'bcrypt'


configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

# root = File.expand_path("..", __FILE__) # sets root directory for project

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file(file_path)
  file = File.read(file_path)
  
  if file_path[-3..-1] == '.md'
    render_markdown(file)
  else
    file
  end
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def user_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test", __FILE__)
  else
    File.expand_path("..", __FILE__)
  end
end

def valid_doc_name?(doc_name)
  if doc_name.empty?
    session[:message] = "A name is required."
    false
  elsif ['.txt', '.md'].none?(File.extname(doc_name))
    session[:message] = "File name must end in .txt or .md"
    false
  else
    true
  end
end

def signed_in?
session[:username] == nil ? false : true
end

def redirect_to_index
  session[:message] = "You must be signed in to do that."
  redirect '/' 
end

def load_users
  file_path = File.join(user_path + "/users.yaml")
  YAML.load(File.read(file_path))
end

def load_pending_users
  file_path = File.join(user_path + "/pending_users.yaml")
  YAML.load(File.read(file_path))
end

def valid_credentials?(username, password)
  users = load_users
  
  if users.keys.include?(username)
    bcrypt_password = BCrypt::Password.new(users[username])
    bcrypt_password == password
  else
    false
  end
end

def duplicate_file(original_file_name, original_file_path)
    original_file = File.open(original_file_path)
    
    File.new("#{data_path}/" + "copy_" + original_file_name, "w")
    File.open("#{data_path}/" + "copy_" + original_file_name, "w") { |f| f.write original_file.read }
    original_file.close
    
    session[:message] = "Duplicate of #{original_file_name} has been created."
end

get '/' do
  @file_names = Dir.children(data_path)

  erb :index, layout: :layout
end

get '/new_document' do
  redirect_to_index unless signed_in?
  
  erb :new_document, layout: :layout
end

get '/:file_name' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)

  if File.exist?(file_path)
    load_file(file_path)
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/'
  end
end

get '/:file_name/edit' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)
  
  redirect_to_index unless signed_in?

  if File.exist?(file_path)
    @content = load_file(file_path)
    
    erb :edit, layout: :layout
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/'
  end
end

get '/users/signin' do
  
  erb :signin, layout: :layout
end

get '/users/signout' do
  session[:username] = nil
  session[:signed_in] = false
  session[:message] = "You have been signed out."
  redirect '/'
end

get '/users/register' do
  
  erb :register, layout: :layout
end

post '/new_document' do
  doc_name = params[:name_document].strip
  
  redirect_to_index unless signed_in?
  
  if valid_doc_name?(doc_name) == false
    redirect 'new_document'
  else
    File.new("#{data_path}/" + "#{doc_name}", 'w')
    session[:message] = "#{doc_name} was created."
    redirect '/'
  end
end

post '/:file_name/duplicate' do
  original_file_name = params[:file_name]
  original_file_path = File.join(data_path, original_file_name)
  
  if File.exist?(original_file_path)
    duplicate_file(original_file_name, original_file_path)
    redirect '/'
  else
    session[:message] = "#{original_file_name} does not exist."
    redirect '/'
  end
end

post '/users/signin' do
  if valid_credentials?(params[:username], params[:password])
    session[:username] = params[:username]
    session[:signed_in] = true
    
    session[:message] = 'Welcome!'
    redirect '/'
  else
    session[:temp_user] = params[:username]
    session[:message] = "Invalid Credentials"
    status 422
    erb :signin
  end
end

def valid_new_username?(new_username)
  users = load_users
  if users.keys.include?(new_username) 
    session[:requsted_user_name] = new_username
    session[:message] = "#{new_username} is already an existing username."
    false
  else
    session[:requsted_user_name] = new_username
    session[:message] = "#{new_username} has been submitted for approval"
    true
  end
end

def valid_new_password?(new_password1, new_password2)
  if new_password1 == new_password2
    true
  else
    session[:message] = "Both passwords must match."
    false
  end
end

post '/users/register' do
  new_username = params[:username]
  new_password1 = params[:password1]  #neeed to BCrypt
  new_password2 = params[:password2]  #neeed to BCrypt
  
  if valid_new_username?(new_username) && valid_new_password?(new_password1, new_password2)
    bcrypt_password = BCrypt::Password.create(new_password1)
    file = File.open(user_path + '/pending_users.yaml', "r")
    data_string = file.read
    data = YAML.load(data_string)
    data[new_username] = bcrypt_password
    data = YAML.dump(data)
    file.close
    File.open(user_path + '/pending_users.yaml', "w") { |f| f.write data }

    
    redirect '/users/register'
  else
    redirect '/users/register'
  end
end

post '/:file_name/update' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)

  redirect_to_index unless signed_in?

  if File.exist?(file_path)
    File.open(file_path, "w") { |f| f.write params[:edit_content] }

    session[:message] = "#{file_name} has been updated."
    redirect '/'
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/'
  end  
end

post '/:file_name/delete' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)
  
  redirect_to_index unless signed_in?
  
  if File.exist?(file_path)
    File.delete(file_path)
    
    session[:message] = "#{file_name} has been deleted."
    redirect '/'
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/'
  end 
end

