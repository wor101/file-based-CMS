require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

# configure do
#   enable :sessions
#   set :session_secret, 'secret'
#   set :erb, :escape_html => true
# end

root = File.expand_path("..", __FILE__) # sets root directory for project

get '/' do
  @file_names = Dir.children(root + "/data/")
  @files = @file_names.map { |file_name| { name: file_name, data: File.new("data/#{file_name}") } }
  
  erb :index, layout: :layout
end

get '/:file_name' do
  file = File.new(root + "/data/#{params[:file_name]}")
  
  # headers["Content-Type"] = "text/plain" # this will tell page to display everything as txt (already using erb template so no point)
  @file_data = file.read

  erb :content, layou: :layout
end