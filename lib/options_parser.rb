# OptionsParser
#
#   https://gist.github.com/ccb267866ad9f602d45b
#   Converts a given list into an options hash. It only handles getopt_long style options.
#
# @example
#   args = %w(--foo --no-bar --baz 2 --fruit apple --fruit orange --temp 10.25)
#   OptionParser.new(args).options
#
# @param  [Array]
# @return [Hash]
class OptionsParser
  def initialize list
    @list = list.reverse
  end

  def options
    list    = @list.dup
    options = {}
    while arg = list.shift
      case arg
        when %r{^--(?<option>[^=]+)=(?<value>.+)}
          option, value = $~[:option].to_sym, $~[:value]
          options[option] = options[option] ? [options[option], value].flatten : value
        when %r{^--}
          neg, option = arg.sub(%r{^--}, '').scan(%r{^(no-)?(.+)$}).flatten
          options[option.to_sym] = !neg
        else
          case arg
            when /^\d+$/       then arg = arg.to_i
            when /^\d+\.\d+$/  then arg = arg.to_f
          end

          option = list.shift.sub(%r{^--}, '').to_sym
          options[option] = options[option] ? [options[option], arg].flatten : arg
      end
    end
    options
  end
end
