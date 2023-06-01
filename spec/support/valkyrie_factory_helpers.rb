# frozen_string_literal: true
module Hyrax
  module ValkyrieFactoryHelpers
    def create(factory_name, *traits_and_overrides, &block)
      mapped_factory = case factory_name
                       when :generic_work, :work
                         :monograph
                       when :file_set
                         :hyrax_file_set
                       when :collection
                         :hyrax_collection
                       when :admin_set
                         :hyrax_admin_set
                       end

      if mapped_factory
        FactoryBot.valkyrie_create(mapped_factory, *traits_and_overrides, &block)
      else
        super(factory_name, *traits_and_overrides, &block)
      end
    end
  end
end
