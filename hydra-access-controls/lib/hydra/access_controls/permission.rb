module Hydra::AccessControls
  class Permission
    def initialize(args)
      @vals = {name: args[:name], access: args[:access], type: args[:type]}
    end

    def persisted?
      false
    end

    def [] var
      @vals[var]
    end

    def name
      self[:name]
    end

    def access
      self[:access]
    end

    def type
      self[:type]
    end

    def _destroy
      false
    end

    def == other
      other.is_a?(Permission) && self.name == other.name && self.type == other.type && self.access == other.access
    end

  end
end
