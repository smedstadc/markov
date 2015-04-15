require_relative 'markov'
require 'time'

def create_corpus(file)
  started = Time.now
  corpus = MessageCorpus.new
  corpus.insert_from_path('irc_logs')
  corpus.insert_from_path('jabber_logs')
  corpus.save(file)
  ended = Time.now
  ended.to_i - started.to_i
end

elapsed_time = create_corpus('corpus.bin')
puts "Finished in #{elapsed_time} seconds."

