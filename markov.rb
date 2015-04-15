require 'pp'
require 'pathname'
require 'sanitize'
require 'parallel'

class Line
  attr_reader :text

  def initialize(string)
    @text = string.gsub("\t", " ")
  end

  def to_message
    message_pattern = /\A\(\d{1,2}\:\d{1,2}\:\d{1,2}\s\w{2}\)\s(\w+)\:\s(.+)/
    if @text.match message_pattern
      Message.new(username: $1, text: $2)
    end
  end
end

class Message
  attr_reader :username, :text

  def initialize(args={})
    @username = args[:username]
    @text = args[:text]
  end

  def to_s
    "#{@username}: #{@text}"
  end
end

class MessageReader
  def load(path, &block)
    File.foreach(path) do |text|
      line = Line.new(Sanitize.clean(text))
      message = line.to_message
      yield message if message
    end
  end

  def load_all(path)
    messages = []
    File.open(path, 'r').each do |text|
      line = line = Line.new(Sanitize.clean(text))
      message = line.to_message
      messages << message if message
    end
    messages
  end
end

class MessageCorpus
  attr_reader :nodes

  def initialize(args={})
    @nodes = args[:file] ? load_file(args[:file]) : {}
  end

  def self.from_path(path)
    started = Time.now
    reader = MessageReader.new
    corpus = MessageCorpus.new
    path = Pathname.new(path)
    files = Dir.glob(path.join('*.html')) + Dir.glob(path.join('*.txt'))

    result = Parallel.map(files, in_processes: 8) do |file|
      puts "loading #{file}"
      lines = reader.load_all(file)
    end

    result.each do |r|
      r.each do |msg|
        corpus.insert msg
      end
    end

    ended = Time.now
    puts "Finished in #{ended.to_i - started.to_i} seconds."
    corpus
  end

  def save(path)
    File.open(path, 'w+') {|file| Marshal.dump(@nodes, file)}
    puts "dumped nodes to #{path}"
  end

  def load(path)
    @nodes = load_file(path)
  end

  def insert(message)
    unless message.username == "bot_tooper" or message.username == "bottooper"
      words = message.text.split(' ')
      recursive_insert words
    end
  end

  def insert_from_path(path)
    started = Time.now
    reader = MessageReader.new
    path = Pathname.new(path)
    files = Dir.glob(path.join('*.html')) + Dir.glob(path.join('*.txt'))

    result = Parallel.map(files, in_processes: 8) do |file|
      puts "loading #{file}"
      lines = reader.load_all(file)
    end

    result.each do |r|
      r.each do |msg|
        insert msg
      end
    end

    ended = Time.now
    puts "insert_from_path finished in #{ended.to_i - started.to_i} seconds."
  end

  private
  def recursive_insert(words)
    unless words.size < 3
      key = [words[0], words[1]]
      word = words[2]
      unless @nodes.has_key? key
        @nodes[key] = CorpusNode.new()
      end
      @nodes[key].insert word
      recursive_insert words[1..words.size]
    end
  end

  def load_file(path)
    File.open(path, 'r') {|file| Marshal.load(file)}
  end
end

class CorpusNode
  attr_reader :frequencies

  def initialize()
    @frequencies = Hash.new(0)
  end

  def insert(word)
    @frequencies[word] += 1
  end

  def next
    possible = []
    @frequencies.each {|k, v| v.times {possible << k}}
    possible.shuffle.first
  end

  def to_s
    "#{@key} #{@frequencies}"
  end
end

class ChainGenerator
  def initialize(corpus)
    @corpus = corpus
  end

  def generate(key)
    node = @corpus.nodes[key.last(2)]
    next_word = node.next if node
    if next_word
      key.push next_word
      generate(key)
    else
      key.join(" ")
    end
  end
end
