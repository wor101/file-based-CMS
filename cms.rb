require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'

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

post '/users/signin' do
  users = load_users
  
  
  if users.keys.include?(params[:username]) && users[params[:username]] == params[:password]
    session[:username] = params[:username]
    session[:signed_in] = true
    
    session[:message] = 'Welcome!'
    redirect '/'
  
  # if params[:username] == 'admin' && params[:password] == 'secret'
  #   session[:username] = params[:username]
  #   session[:signed_in] = true
    
  #   session[:message] = 'Welcome!'
  #   redirect '/'
  else
    session[:temp_user] = params[:username]
    session[:message] = "Invalid Credentials"
    status 422
    erb :signin
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

