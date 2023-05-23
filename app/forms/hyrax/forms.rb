module Hyrax
  module Forms
    ##
    # @api public
    #
    # @example defining a form class using HydraEditor-like configuration
    #   class MonographForm < Hyrax::Forms::ResourceForm(Monograph)
    #     self.required_fields = [:title, :creator, :rights_statement]
    #     # other WorkForm-like configuration here
    #   end
    #
    # @note The returned class will extend +Hyrax::Forms::PcdmObjectForm+, not
    #   only +Hyrax::Forms::ResourceForm+. This is for backwards‐compatibility
    #   with existing Hyrax instances and satisfies the expected general use
    #   case (building forms for various PCDM object classes), but is *not*
    #   necessarily suitable for other kinds of Hyrax resource, like
    #   +Hyrax::FileSet+s.
    def self.ResourceForm(work_class)
      Class.new(Hyrax::Forms::PcdmObjectForm) do
        self.model_class = work_class

        ##
        # @return [String]
        def self.inspect
          return "Hyrax::Forms::ResourceForm(#{model_class})" if name.blank?
          super
        end
      end
    end
  end
end
