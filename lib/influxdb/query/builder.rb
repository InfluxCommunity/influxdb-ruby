module InfluxDB
  module Query # :nodoc: all
    class Builder
      def quote(param)
        if param.is_a?(String)
          "'" + param.gsub(/['"\\\x0]/, '\\\\\0') + "'"
        elsif param.is_a?(Integer) || param.is_a?(Float) || param == true || param == false
          param.to_s
        else
          raise ArgumentError, "Unexpected parameter type #{p.class} (#{p.inspect})"
        end
      end

      def build(query, params)
        params =  case params
                  when Array then params_from_array(params)
                  when Hash then  params_from_hash(params)
                  when NilClass then {}
                  else raise ArgumentError, "Unsupported #{params.class} params"
                  end
        query % params
      rescue KeyError => e
        raise ArgumentError, e.message
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
