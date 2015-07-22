module Cmn
  module Commands
    class ScrapAdjective < Scrap
      def execute
        thrs = []

        thrs << Thread.new { find_goal_prepositional_structures }

        thrs.each { |thr| thr.join }
      end

      def find_goal_prepositional_structures
        query = "对|同|和|跟|向|与 [pos='n'] 很 #{@word}"
        results = query_leeds_corpus(query, output: 100) do |context|
          m = context.match
          if ["对", "同", "和", "跟", "向", "与"].include?(m.first.text) && m.last.text == @word
            "#{m.first.text}...#{@word}"
          end
        end
        report_words_with_frequency("Goal Prepositional Structures", results)
      end
    end
  end
end
