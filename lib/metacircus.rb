class Metacircus
  
end

class Metacircus::Repo
  require 'grit'
  require 'curly'

  attr_reader :repo
  def initialize(repo)
    @repo = Grit::Repo.new(repo)
  end

  def post(name)
    post = posts[name]
    raise "post not found" unless post
    post.process
    # add disqus
    disqus = pages["disqus"]
    disqus.dom.at("disqus_hook").replace(Curly.node("{a[href http://www.metacircus.com/post/#{post.name}#disqus_thread]Comments}"))
    post.dom.add_child(disqus.dom)
    
    layout = self.layout["default"]
    layout.dom.at("content").replace(post.dom)
    layout.dom.at("title").content = "#{post.title} - Metacircus"
    layout
  end

  def posts
    blobs("post") { |blob|
      Metacircus::Document::Post.new(blob)
    }
  end

  def pages
    blobs("page") { |blob|
      Metacircus::Document::Page.new(blob)
    }
  end

  def layout
    blobs("layout") { |blob|
      Metacircus::Document::Layout.new(blob)
    }
  end

  def index
    index = pages["index"]

    ul = index.dom.at("#hacks")
    posts.values.each { |post|
      li = Curly.node("{li {span #{post.created_time.strftime("%d %b %Y")}} » {a[href post/#{post.name}] #{post.title}}}")
      ul.add_child(li)
    }

    layout = self.layout["default"]
    layout.dom.at("content").replace(index.dom)
    layout
  end
  
  protected
  def blobs(dir)
    (repo.tree / dir).contents.inject({}) { |h,blob|
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
    div = Nokogiri.make("<div></div>")
    dom.children.each do |node|
      div.add_child node
    end

    ##################################################
    # transform
    (div / "prog").each do |node|
      pygmentize(node,node["l"] || node["language"])
    end

    (div / "ruby").each do |node|
      pygmentize(node,"ruby")
    end

    ##################################################
    # markdown
    (div / "md").each do |node|
      md = markdown(node.content)
      # DocumentFragment causes double freed pointer error
      #Nokogiri::XML::DocumentFragment.parse(md)
      frag = Nokogiri::XML::Document.parse("<div>#{md}</div>").root
      node.replace(frag)
    end
    
    @dom = div
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

