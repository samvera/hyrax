module CurationConcerns
  class NullLogger < Logger
    def initialize(*args)
    end

    # allows all the usual logger method calls (warn, info, error, etc.)
    def add(*args, &block)
    end
  end
end
