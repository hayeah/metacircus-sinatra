require 'time'
class Metacircus
end

def Metacircus(repo_path)
  site = Metacircus::Site.new(Metacircus::Repo.new(repo_path))
  site.cache_all
  site
end

class Metacircus::Site
  # sitemap with caching
  def initialize(repo)
    @repo = repo
  end

  # build more sophisticated caching behaviour here...
  def cache_all
    posts
    index
    true
  end

  def post(name)
    raise "post not found" unless post = posts[name]
    post
  end
  
  def posts
    # pp @repo.posts
    @posts ||= @repo.posts.inject({}) do |h,(name,document)|
      h[name] = @repo.layout(document)
      h
    end
  end
  
  def atom_feed
    posts = @repo.posts.values.sort { |p1,p2|
      p2.created_time <=> p1.created_time
    }
    entries = posts.map { |post|
      [:entry,nil,
       [[:title,nil,post.title],
        [:link,{:href => "http://www.metacircus.com/post#{post.name}"}],
        [:updated,nil,post.updated_time.xmlschema],
        [:id,nil,"http://www.metacircus.com/post#{post.name}"],
        [:content,{:type => "html"},post.to_xml]]]
    }
    feed = [:feed,{:'xmlns' => "http://www.w3.org/2005/Atom"},
            [[:title,nil,"Metacircus"],
             [:link,{:href => "http://www.metacircus.com/atom.xml", :rel => "self"}],
             [:link,{:href => "http://www.metacircus.com"}],
             [:updated,nil,[posts.first.updated_time]],
             [:id,nil,"http://www.metacircus.com/"],
             [:author,nil,
              [:name,nil,"Howard Yeh"],
              [:email,nil,"hayeah@gmail.com"]],
             *entries]]
    pp feed
    Curly::XML::Builder.xml(feed).to_xml
  end

  def index
    @index ||= @repo.layout(@repo.index)
  end
end

class Metacircus::Repo
  require 'grit'
  require 'curly'

  attr_reader :git
  def initialize(git)
    @git = Grit::Repo.new(git)
  end

  def post(name)
    posts[name]
  end

  def index
    index = pages["index"]

    ul = index.dom.at("#hacks")
    posts = self.posts.values.sort { |p1,p2|
      p1.created_time <=> p2.created_time
    }.reverse
    posts.each { |post|
      li = Curly.node("{li {span #{post.created_time.strftime("%d %b %Y")}} » {a[href post/#{post.name}] #{post.title}}}")
      ul.add_child(li)
    }
    index
  end

  def posts
    @posts ||= blobs("post") { |blob|
      post = Metacircus::Document::Post.new(blob)
      p [:process,post.name]
      post.process
      # add disqus
      disqus = pages["disqus"]
      disqus.dom.at("disqus_hook").replace(Curly.node("{a[href http://www.metacircus.com/post/#{post.name}#disqus_thread]Comments}"))
      post.dom.add_child(disqus.dom)
      post
    }
  end

  def pages
    blobs("page") { |blob|
      Metacircus::Document::Page.new(blob)
    }
  end

  def layouts
    blobs("layout") { |blob|
      Metacircus::Document::Layout.new(blob)
    }
  end

  def layout(document,name="default")
    layout = layouts[name].dom.clone
    # set title
    layout.at("title").content = document.dom["title"]
    # make a content div to put content
    div = Curly.node("{div.content}")
    content = document.dom.clone
    
    content.children.each { |child|
      div.add_child(child)
    }
    # set layout's content
    layout.at("content").replace(div)
    layout
  end

  protected
  def blobs(dir)
    (git.tree / dir).contents.inject({}) { |h,blob|
      h[blob.name] = block_given? ? yield(blob) : blob
      h
    }
  end
end

class Metacircus::Document
  require 'curly'

  attr_accessor :attributes, :data, :name
  attr_reader :dom
  def initialize(blob)
    @blob = blob
    @id  = @blob.id
    @name = blob.name
    @data = @blob.data
    @dom = Curly.xml(data).root
    @attributes = @dom.attributes.inject({}) { |h,(k,a)|
      h[k] = a.value
      h
    }
  end

  def process
    # no op
  end

  def to_xml
    dom.to_xml
  end

  def [](key)
    attributes[key.to_s]
  end
end

class Metacircus::Document::Page < Metacircus::Document
end

class Metacircus::Document::Layout < Metacircus::Document
end

class Metacircus::Document::Post < Metacircus::Document
  require 'tempfile'
  require 'rdiscount'

  def title
    attributes["title"]
  end

  def tags
    attributes["tags"] || []
  end

  def categories
    attributes["categories"] || []
  end

  def timestamps
    @timestamps ||= attributes["timestamps"].split(/\s/).map { |time|
      Time.parse(time.strip)
    }
  end

  def created_time
    timestamps.last
  end

  def updated_time
    timestamps.first
  end
  
  def posted_date
    "%d %b %Y"
  end
  
  def attributes=(h)
    h["categories"].split(",").map(&:strip) if h["categories"]
    h["tags"].split(",").map(&:strip) if h["tags"]
    @attributes = h
  end

  def process
    div = Curly.node("{div}")
    dom.children.each do |child|
      div << child
    end
    @dom = div
    ##################################################
    # transform
    (dom / "prog").each do |node|
      pygmentize(node,node["l"] || node["language"])
    end

    (dom / "ruby").each do |node|
      pygmentize(node,"ruby")
    end

    ##################################################
    # markdown
    (dom / "md").each do |node|
      md = markdown(node.content)
      # DocumentFragment causes double freed pointer error
      #Nokogiri::XML::DocumentFragment.parse(md)
      frag = Nokogiri::XML::Document.parse("<div>#{md}</div>").root
      node.replace(frag)
    end
  end

  protected

  def markdown(text)
    RDiscount.new(text).to_html
  end
  
  def pygmentize(node,language)
    code = node.inner_text.strip
    Tempfile.open("pygmentize") { |file|
      file.puts(code)
      file.flush
      pygmentize_html = `pygmentize -l #{language} -f html #{file.path}`
      node.replace(pygmentize_html)
    }
  end
end

