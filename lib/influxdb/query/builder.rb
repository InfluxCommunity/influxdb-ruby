module InfluxDB
  module Query # :nodoc: all
    class Builder
      def build(query, params)
        case params
        when Array    then params = params_from_array(params)
        when Hash     then params = params_from_hash(params)
        when NilClass then params = {}
        else raise ArgumentError, "Unsupported #{params.class} params"
        end

        query % params

      rescue KeyError => e
        raise ArgumentError, e.message
      end

      def quote(param)
        case param
        when String, Symbol
          "'" + param.to_s.gsub(/['"\\\x0]/, '\\\\\0') + "'"
        when Integer, Float, TrueClass, FalseClass
          param.to_s
        else
          raise ArgumentError, "Unexpected parameter type #{param.class} (#{param.inspect})"
        end
      end

      private

      def params_from_hash(params)
        params.each_with_object({}) do |(k, v), hash|
          hash[k.to_sym] = quote(v)
        end
      end

      def params_from_array(params)
        params.each_with_object({}).with_index do |(param, hash), i|
          hash[(i + 1).to_s.to_sym] = quote(param)
        end
      end
    end
  end
end
