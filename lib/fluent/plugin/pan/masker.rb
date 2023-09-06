module Fluent::PAN
  class Masker

    CHECKSUM_FUNC = {
      luhn: ->(digits){
        sum = 0
        alt = false
        digits.reverse.each do |i|
          if alt
            i *= 2
            if i > 9
              i -= 9
            end
          end
          sum += i
          alt = !alt
        end
        (sum % 10).zero?
      },
      none: ->digits{
        # Do nothing. always satisfied.
        true
      }
    }

    def initialize(regexp, checksum_algorithm, mask, force=false)
      @regexp = regexp
      @mask = mask
      @force = force
      @checksum_func = CHECKSUM_FUNC[checksum_algorithm]
    end

    def mask_if_found_pan(orgval)
      filtered = orgval.to_s.gsub(@regexp) do |match|
        pan = match.split("").select { |i| i =~ /\d/ }.map { |j| j.to_i }

        if valid?(pan)
           match = match.gsub(@regexp, @mask)
        else
          match
        end
      end

      retval = filtered
      if orgval.is_a? Integer
        if numerals_mask?
          retval = filtered.to_i
        else
          if @force
            retval = filtered
          else
            retval = orgval
          end
        end
      end
      retval
    end

    def valid?(pan)
      @checksum_func.call(pan)
    end

    def numerals_mask?
      if @mask.to_s =~ /^\d+$/
        true
      else
        false
      end
    end
  end
end
