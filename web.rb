require 'rubygems'
require 'sinatra'

require 'lib/metacircus'

blog = Metacircus::Repo.new("repo")

set :public, 'repo/static'

get '/' do
  blog.index.to_xml
end

get '/post/:name' do
  blog.post(params[:name]).to_xml
end
