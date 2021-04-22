require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

root = File.expand_path("..", __FILE__) # sets root directory for project

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

get '/' do
  @file_names = Dir.children(root + "/data/")
  @files = @file_names.map { |file_name| { name: file_name, data: File.new("data/#{file_name}") } }
  
  erb :index, layout: :layout
end

get '/:file_name' do
  file_name = params[:file_name]
  file_path = root + "/data/" + file_name
  
  if File.exist?(file_path)
    load_file(file_path)
  else
    session[:error] = "#{file_name} does not exist."
    redirect '/'
  end
  
=begin
  if Dir.children(root + "/data/").none?(file_name)
    session[:error] = "#{file_name} does not exist."
    redirect '/'
  elsif file_name[-3..-1] == '.md'
    render_markdown(load_file(file_name))
  else
    # headers["Content-Type"] = "text/plain" # this will tell page to display everything as txt (already using erb template so no point)
    @file_data = load_file(file_name)
    erb :content, layou: :layout
  end
=end

end