module Cmn
  module Crawlers
    class Contexts
      def initialize(ary = [])
        @array = ary
      end

      def to_a
        @array.dup
      end

      def format(opts = {})
        @array.map { |c| c.format(opts) }.join("\n")
      end
    end

    class Context
      attr_reader :before, :match, :after
      def initialize(b, m, a)
        @before, @match, @after = b, m, a
      end

      def constituents
        @before + @match + @after
      end

      def to_s
        b, m, a = [@before, @match, @after].map { |ary| ary.map(&:text).join }
        b + m.bold.green + a
      end

      def format(opts = {})
        if l = opts[:length]
          match_s = @match.map(&:text).join

          sides_l = l - match_s.length
          left_l = sides_l / 2
          right_l = sides_l - left_l

          r = /.{0,#{left_l}}$/
          s = @before.map(&:text).join

          left_s = @before.map(&:text).join.match(/.{0,#{left_l}}$/)[0].rjust(left_l)
          right_s = @after.map(&:text).join.match(/^.{0,#{right_l}}/)[0].ljust(right_l)

          left_s + match_s.bold.green + right_s
        else
          to_s
        end
      end
    end

    class Constituent
      attr_reader :text, :part_of_speech
      def initialize(text, pof)
        @text, @part_of_speech = text, pof
      end
    end
  end
end
