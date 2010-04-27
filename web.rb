require 'rubygems'
require 'sinatra'

require 'newrelic_rpm'

require 'lib/metacircus'

blog = Metacircus("repo")

set :public, 'repo/static'

get '/' do
  blog.index.to_xml
end

get '/atom.xml' do
  blog.atom_feed.to_xml
end

get '/post/:name' do
  blog.post(params[:name]).to_xml
end

