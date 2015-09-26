module Cmn
  module Commands
    class ScrapVerb < Scrap
      def execute
        thrs = []

        case @word
        when /^.{1}$/
          #thrs << Thread.new { find_verbal_measure_words }
          #thrs << Thread.new { find_governmental_words }
          thrs << Thread.new { find_complemental_forms_as_verb }
          thrs << Thread.new { find_complemental_forms_as_complement }
        when /^.{2}$/
          # @fixme
          #find_complemental_infix
        when /^.(不|得)[^得]$/
          find_complemental_without_infix
          find_symetrical_complemental_infix
        else
          raise "Unhandled case !!"
        end

        #thrs << Thread.new { find_gei_structures }
        #thrs << Thread.new { find_ba_gei_structures }
        #thrs << Thread.new { find_ba_structures }
        #thrs << Thread.new { find_goal_prepositional_structures }
        #thrs << Thread.new { find_locative_prepositional_structures }
        #thrs << Thread.new { find_yu2_structure }
        #thrs << Thread.new { find_wei2_structure }

        thrs.each { |thr| thr.join }
      end

      def find_verbal_measure_words
        query = "[word='#{@word}'&pos='v'] 一 [pos='q']"
        results = query_leeds_corpus(query, output: 500) do |context|
          if context.after.first.part_of_speech != "/n"
            context.match.last
          end
        end
        @measure_words = filter_by_frequency(results, 1.0/5)

        report_words_with_frequency("Verbal Measure Words", @measure_words)
      end

      def find_governmental_words
        @governmental_words = query_leeds_corpus "[word='#{@word}.'&pos='v|a']"

        report_words_with_frequency("Governmental Words", @governmental_words)
      end


      # ++++++++++++ Complements +++++++++++
      #
      # Leeds corpus: different structures:
      #     1. 看见 看-得-见 看-不-见
      #     2. 记得 记-不得 记-不清
      #     3. 靠得住 靠不住 (靠住 doesn't exist)

      def find_complemental_forms_as_verb
        results = find_complemental_forms(as: :verb)
        puts " Complemental forms as verb ".center(60, '=')
        puts table(results)
      end

      def find_complemental_forms_as_complement
        results = find_complemental_forms(as: :complement)
        puts " Complemental forms as complement ".center(60, '=')
        puts table(results)
      end

      def find_complemental_forms(opts = {})
        query = opts[:as] == :verb ? @word + '*' : '*' + @word
        results = Crawlers::MDBGCrawler.new(search: query).crawl

        results.each_with_object({}) do |w, obj|
          if w =~ /^(.)(得|不)(.[^儿]?)$/
            dis = $1 + $3
            obj[dis] ||= []
            pos = $2 == "得" ? 1 : 2
            obj[dis][pos] = w
            results.include?(dis) && obj[dis][0] = dis
          end
        end.values
      end

      def table(data)
        data.map { |row|
          row.map { |cell|
            l = cell.to_s.length
            cell.to_s.ljust(10-l)
          }.join
        }.join("\n")
      end

      # Can check in a dictionary first to speed up the research.
      #
      def find_complemental_infix
        verb, complement = @word.chars

        if complement == "得"
          query = "#{verb} 不得"
        else
          query = "#{verb} 不|得 #{complement}"
        end
        @complemental_infix = query_leeds_corpus(query) do |context|
          context.match.map(&:text).join
        end

        report_words_with_frequency("Complemental Infixes", @complemental_infix)
      end

      def find_symetrical_complemental_infix
        verb, part, comp = @word.chars
        other = part == "得" ? "不" : "得"
        sym = verb + other + comp

        if Crawlers::YellowBridgeCrawler.new({search: sym}).crawl.found?
          @sym_comp_infix = sym
        end

        puts "Symetrical Complemental Infix: " + (@sym_comp_infix || "NONE (#{sym} doesn't exist)")
      end

      def find_complemental_without_infix
        mono_v, _, comp = @word.chars
        verb = mono_v + comp

        if Crawlers::YellowBridgeCrawler.new({search: verb}).crawl.found?
          @without_infix = verb
        end

        puts "Complemental verb without infix: " + (@without_infix || "NONE (#{verb} doesn't exist)")
      end


      # +++++++++++++++ Structures +++++++++++++++

      def find_gei_structures
        query = "给 [pos='n'] #{@word}"
        results = query_leeds_corpus(query, output: 100) do |context|
          match_reversible_structure(context, "给")
        end
        filtered = results.select { |(_, count)| count > 10 }
        report_words_with_frequency("给 Structures", filtered)
      end

      def find_ba_gei_structures
        query = "把 [pos='n'] 给 [pos='n'] [word='#{@word}'&pos='v']"
        regular = query_leeds_corpus(query, output: 100) do |context|
          m = context.match
          if m.first.text == "把" && m[2].text == "给" && m.last.text == @word
            "把...给...#{@word}"
          end
        end

        query = "把 [pos='n'] [word='#{@word}'&pos='v'] 给"
        reversed = query_leeds_corpus(query, output: 100) do |context|
          m = context.match
          if m.first.text == "把" && m.last(2).map(&:text) == [@word, "给"]
            "把...#{@word}给..."
          end
        end

        report_words_with_frequency("把 + 给 Structures", regular + reversed)
      end

      def find_ba_structures
        query = "把 [pos='n'] [word='#{@word}'&pos='v'] ."
        results = query_leeds_corpus(query, output: 100) do |context|
          m = context.match
          if m.first.text == "把" && m.last.text == @word &&
              !["给", "的"].include?(context.after.first.text)
            "把...#{@word}"
          end
        end
        filtered = results.select { |(_, count)| count > 10 }
        report_words_with_frequency("把 Structures", filtered)
      end

      def find_goal_prepositional_structures
        query = "对|同|和|跟|向|与 [pos='n'] [word='#{@word}'&pos='v']"
        results = query_leeds_corpus(query, output: 100) do |context|
          m = context.match
          if ["对", "同", "和", "跟", "向", "与"].include?(m.first.text) && m.last.text == @word
            "#{m.first.text}...#{@word}"
          end
        end
        report_words_with_frequency("Goal Prepositional Structures", results)
      end

      def find_locative_prepositional_structures
        query = "在|到 [pos='n'] [word='#{@word}'&pos='v']"
        results = query_leeds_corpus(query, output: 100) do |context|
          match_reversible_structure(context, "在", "到")
        end
        #filtered = results.select { |(_, count)| count > 10 }
        report_words_with_frequency("Locative Structures", results)
      end

      def find_yu2_structure
        query = "[word='#{@word}'&pos='v'] 于 [pos='n']"
        results = query_leeds_corpus(query, output: 100) do |context|
          "#{@word}于..."
        end
        report_words_with_frequency("于 Structure", results)
      end

      def find_wei2_structure
        query = "[word='#{@word}'&pos='v'] [pos='n'] 为 [pos='v']"
        results = query_leeds_corpus(query, output: 100) do |context|
          m = context.match
          if m.first.text == @word && m[2].text == "为"
            "#{@word}...为..."
          end
        end
        report_words_with_frequency("为 Structure", results)
      end

      def match_reversible_structure(context, *preps)
        prep = context.match.first.text
        if preps.include?(prep)
          if context.before.last.text == @word
            "#{@word}#{prep}..."
          elsif context.match.last.text == @word
            "#{prep}...#{@word}"
          end
        end
      end

    end
  end
end
