module Cmn
  module Crawlers
    class YellowBridgeCrawler
      URL = "http://www.yellowbridge.com/chinese/dictionary.php"

      def initialize(query = {})
        @query = query
      end

      def crawl
        agent = Mechanize.new
        page = agent.get(URL)

        form = page.forms.first
        form.add_field! 'word', @query[:search]

        page = agent.submit(form)

        if page.at('.sad')
          @found = false
        else
          @found = true
          # Scrap data here...
        end

        return self
      end

      def found?
        @found
      end
    end
  end
end

