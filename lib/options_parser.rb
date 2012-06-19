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
        when %r{^--}
          neg, opt = arg.sub(%r{^--}, '').scan(%r{^(no-)?(.+)$}).flatten
          options[opt.to_sym] = !neg
        else
          case arg
            when /^\d+$/       then arg = arg.to_i
            when /^\d+\.\d+$/  then arg = arg.to_f
          end

          opt = list.shift.sub(%r{^--}, '').to_sym
          options[opt] = options[opt] ? [options[opt], arg].flatten : arg
      end
    end
    options
  end
end
