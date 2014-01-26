require 'json'

module InfluxDB

  class PointValue
    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def dump
      if value.is_a?(Array) || value.is_a?(Hash)
        JSON.generate(value)
      else
        value
      end
    end

    def load
      if json?
        begin
          JSON.parse(value)
        rescue JSON::ParserError => e
          raise InfluxDB::JSONParserError, e.message
        end
      else
        value
      end
    end

    def json?
      value =~ /(
        # define subtypes and build up the json syntax, BNF-grammar-style
        # The {0} is a hack to simply define them as named groups here but not match on them yet
        # I added some atomic grouping to prevent catastrophic backtracking on invalid inputs
        (?<number>  -?(?=[1-9]|0(?!\d))\d+(\.\d+)?([eE][+-]?\d+)?){0}
        (?<boolean> true | false | null ){0}
        (?<string>  " (?>[^"\\\\]* | \\\\ ["\\\\bfnrt\/] | \\\\ u [0-9a-f]{4} )* " ){0}
        (?<array>   \[ (?> \g<json> (?: , \g<json> )* )? \s* \] ){0}
        (?<pair>    \s* \g<string> \s* : \g<json> ){0}
        (?<object>  \{ (?> \g<pair> (?: , \g<pair> )* )? \s* \} ){0}
        (?<json>    \s* (?> \g<number> | \g<boolean> | \g<string> | \g<array> | \g<object> ) \s* ){0}
        )
      \A \g<json> \Z
      /uix
    end
  end
end