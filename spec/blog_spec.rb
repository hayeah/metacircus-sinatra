require 'spec/spec_helper'

describe "Blog" do
  let(:git) {
    Grit::Repo.new("")
  }
  
  let(:repo) {
    Metacircus::Repo.new("repo")
  }

  let(:site) {
    Metacircus::Site.new(repo)
  }

  it "builds atom feed" do
    puts site.atom_feed
  end

  it "layouts" do
    # puts repo.layout(repo.index).id
    # puts repo.layout(repo.index).id
    # puts repo.layout(repo.post("rant-lovely")).id

    #puts repo.layout(repo.post("rant-lovely")).to_xml
    p site.post("rant-lovely").id
    p site.post("long-day-ended-with-c").id
  end

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
