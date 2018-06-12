module Hyrax
  # This is an abstract class to provide select options from a
  # questioning authority backed authority
  class QaSelectService
    attr_reader :authority

    def initialize(authority_name)
      @authority = Qa::Authorities::Local.subauthority_for(authority_name)
    end

    ##
    # @return [Array<String, #to_s>]
    def select_all_options
      authority.all.map do |element|
        [element[:label], element[:id]]
      end
    end

    # @return [Array<String, #to_s>]
    def select_active_options
      active_elements.map { |e| [e[:label], e[:id]] }
    end

    ##
    # @return [Boolean] whether the key is active
    #
    # @raise [KeyError] when the key has no `active:` status
    def active?(id)
      authority.find(id).fetch('active')
    end

    ##
    # @param id [String]
    #
    # @return [String] the label for the authority
    #
    # @yield when no 'term' value is present for the id
    # @yieldreturn [String] an alternate label to return
    #
    # @raise [KeyError] when no 'term' value is present for the id
    def label(id, &block)
      authority.find(id).fetch('term', &block)
    end

    ##
    # @return [Enumerable<Hash>]
    #
    # @raise [KeyError] when no 'term' value is present for the id
    def active_elements
      authority.all.select { |e| e.fetch('active') }
    end
  end
end
