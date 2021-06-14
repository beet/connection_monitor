=begin
Refinement to wrap strings in ANSI colour codes that colourize them when
printing to a terminal:

    using ColourizedStrings

    "red".red
    => "\e[31mred\e[0m"

    "green".green
    => "\e[32mgreen\e[0m"

Have predefined a few colours:

* red
* green
* yellow
* blue
* pink
* light_blue

=end
module ColourizedStrings
  refine String do
    def red
      colorize(31)
    end

    def green
      colorize(32)
    end

    def yellow
      colorize(33)
    end

    def blue
      colorize(34)
    end

    def pink
      colorize(35)
    end

    def light_blue
      colorize(36)
    end

    def bold
      "\033[1m#{self}\033[0m"
    end

    def light
      "\033[2m#{self}\033[0m"
    end

    def underline
      "\033[4m#{self}\033[0m"
    end

    def inverted
      "\033[7m#{self}\033[0m"
    end

    private

    def colorize(color_code)
      "\e[#{color_code}m#{self}\e[0m"
    end
  end
end
