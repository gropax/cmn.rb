module Cmn
  module Commands
    class ScrapNoun < Scrap
      def execute
        find_measure_words

        if @word.size == 1
          find_governmental_words
        end

        find_governmental_collocations
      end

      def find_measure_words
        results = query_leeds_corpus "[pos='q'] [word='#{@word}'&pos='n']"
        @measure_words = filter_by_frequency(results, 1.0/5)

        report_words_with_frequency("Measure Words", @measure_words)
      end


      def find_governmental_words
        @governmental_words = query_leeds_corpus "[word='.#{@word}'&pos='v|a']"

        report_words_with_frequency("Governmental Words", @governmental_words)
      end

      # Find collocations of the form [V N]
      #
      def find_governmental_collocations
        query = "[pos='v'] [word='#{@word}'&pos='n']"
        results = query_leeds_corpus(query, output: 500) do |context|
          # Collect verbs near the noun in context
          (context.before.last(4) + context.match).select { |c| c.part_of_speech == '/v' }
        end

        @governmental_collocations = filter_by_frequency(results, 1.0/5)

        report_words_with_frequency("Governmental Collocations", @governmental_collocations)
      end
    end
  end
end
