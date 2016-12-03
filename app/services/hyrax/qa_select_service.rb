module Hyrax
  # This is an abstract class to provide select options from a
  # questioning authority backed authority
  class QaSelectService
    attr_reader :authority

    def initialize(authority_name)
      @authority = Qa::Authorities::Local.subauthority_for(authority_name)
    end

    def select_all_options
      authority.all.map do |element|
        [element[:label], element[:id]]
      end
    end

    def select_active_options
      active_elements.map { |e| [e[:label], e[:id]] }
    end

    def active?(id)
      authority.find(id).fetch('active')
    end

    def label(id)
      authority.find(id).fetch('term')
    end

    def active_elements
      authority.all.select { |e| active?(e.fetch('id')) }
    end
  end
end
