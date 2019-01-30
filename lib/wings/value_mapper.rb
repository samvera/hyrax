module Wings
  class ValueMapper < ::Valkyrie::ValueMapper
  end

  class ResourceMapper < ValueMapper
    ValueMapper.register(self)

    def self.handles?(value)
      value.respond_to?(:term?) && value.term?
    end

    def result
      value.to_term
    end
  end

  class EnumerableMapper < ValueMapper
    ValueMapper.register(self)

    def self.handles?(value)
      value.is_a?(Enumerable)
    end

    def result
      value.map { |v| calling_mapper.for(v).result }
    end
  end
end
