require_relative 'markov'

corpus = MessageCorpus.new(file: 'corpus.bin')
generator = ChainGenerator.new(corpus)
keys = corpus.nodes.keys.shuffle
25.times do
  key = keys.shift
  puts generator.generate(key)
end
