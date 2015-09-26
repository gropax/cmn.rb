module Cmn
  module Crawlers
    class MDBGCrawler
      URL = "http://www.mdbg.net/chindict/chindict.php"

      def initialize(query = {})
        @query = query
      end

      def crawl
        agent = Mechanize.new
        page = agent.get(URL)

        form = page.forms.first
        form.add_field! "wdqb", @query[:search]

        page = agent.submit(form)

        page.search(".wordresults .row").map do |row|
          row.search(".head .hanzi span").map(&:text).join.squeeze
        end
      end
    end
  end
end

