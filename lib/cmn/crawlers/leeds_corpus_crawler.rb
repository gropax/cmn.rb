module Cmn
  module Crawlers
    class LeedsCorpusCrawler
      URL = "http://corpus.leeds.ac.uk/query-zh.html"

      def initialize(query = {})
        @query = query
      end

      def crawl
        agent = Mechanize.new
        page = agent.get(URL)

        form = page.form 'reqForm'
        form.searchstring = @query[:search]

        if output = @query[:output]
          form.add_field! 'terminate', output
        end

        if side = @query[:sort_by_side]
          form.add_field! 'sort2', side
        end

        page = agent.submit(form)
        contexts = page.search("form table tr").map { |tr|
          left, mid, right = tr.search("td")[2..4].map { |td|
            constituents(td.search "span")
          }
          Context.new(left, mid, right)
        }

        Contexts.new(contexts)
      end

      def constituents(spans)
        spans.map do |span|
          text = span.text.gsub(/\s/, '')
          pof = span["title"].gsub(/\s|\\/, '')
          Constituent.new(text, pof)
        end
      end
    end
  end
end
