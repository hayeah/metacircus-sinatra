require 'spec/spec_helper'

describe "Blog" do
  let(:git) {
    Grit::Repo.new("")
  }
  
  let(:repo) {
    Metacircus::Repo.new("repo")
  }

  it "shows post" do
    # pp repo.posts
    # pp repo.pages
    ## pp repo.post("rant-lovely")
  end
  
  it "shows index" do
    # pp repo.posts
    # pp repo.pages
    puts repo.index.to_xml
  end
  it "gets posts" do
    repo.posts
  end
  
  it "fails" do
    pp blog
    raise "foo"
  end
end
