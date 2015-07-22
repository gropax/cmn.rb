module Cmn
  module Commands
    class Scrap
      def initialize(args, opts)
        @word = args.first
        @opts = opts
      end


      private

        def query_leeds_corpus(query, opts = {}, &blk)
          contexts = Crawlers::LeedsCorpusCrawler.new({
            search: query,
            output: 100,
            sort_by_side: :left,
          }.merge(opts)).crawl

          results = contexts.to_a.each_with_object({}) { |c, hsh|
            words = blk ? Array(blk.call c).flatten.compact : c.match[0..1]
            words.each { |w|
              text = w.is_a?(String) ? w : w.text
              hsh[text] ||= 0
              hsh[text] += 1
            }
          }

          results.sort_by { |_, count| -count }
        end

        def filter_by_frequency(ary, ratio)
          max = ary.map(&:last).max
          ary.select { |_, count| count > max * ratio }
        end

        def report_words_with_frequency(title, data)
          puts " #{title} ".center(60, '=')
          puts data.map { |word, freq|
            word.ljust(8) + ":" + freq.to_s.rjust(8)
          }.join("\n")
        end
    end
  end
end
