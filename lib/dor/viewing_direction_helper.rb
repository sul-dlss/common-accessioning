# frozen_string_literal: true

module Dor
  # Maps viewing direction / reading order
  class ViewingDirectionHelper
    VIEWING_DIRECTION_FOR_CONTENT_TYPE = {
      'Book (ltr)' => 'left-to-right',
      'Book (rtl)' => 'right-to-left',
      'Book (flipbook, ltr)' => 'left-to-right',
      'Book (flipbook, rtl)' => 'right-to-left',
      'Manuscript (flipbook, ltr)' => 'left-to-right',
      'Manuscript (ltr)' => 'left-to-right'
    }.freeze

    def self.viewing_direction(reading_direction)
      # See https://consul.stanford.edu/pages/viewpage.action?spaceKey=chimera&title=DOR+content+types%2C+resource+types+and+interpretive+metadata
      case reading_direction
      when 'ltr'
        'left-to-right'
      when 'rtl'
        'right-to-left'
      else
        message = "reading direction in contentMetadata.xml is '#{reading_direction}'; defaulting to ltr"
        Honeybadger.notify("[WARNING] #{message}")
        'left-to-right'
      end
    end
  end
end
