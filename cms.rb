require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

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

get '/' do
  @file_names = Dir.children(data_path)
  #@files = @file_names.map { |file_name| { name: file_name, data: File.new("data/#{file_name}") } }
  
  erb :index, layout: :layout
end

get '/new_document' do
  
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
  
  if File.exist?(file_path)
    @content = load_file(file_path)
    
    erb :edit, layout: :layout
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/'
  end
end

post '/new_document' do
  doc_name = params[:name_document].strip
  
  if valid_doc_name?(doc_name) == false
    redirect 'new_document'
  else
    File.new("#{data_path}/" + "#{doc_name}", 'w')
    session[:message] = "#{doc_name} was created."
    redirect '/'
  end
end

post '/:file_name/update' do
  file_name = params[:file_name]
  file_path = File.join(data_path, file_name)

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
  
  if File.exist?(file_path)
    File.delete(file_path)
    
    session[:message] = "#{file_name} has been deleted."
    redirect '/'
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/'
  end  
  
end