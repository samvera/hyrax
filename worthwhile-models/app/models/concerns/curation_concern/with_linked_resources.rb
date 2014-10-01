module CurationConcern
  module WithLinkedResources
    extend ActiveSupport::Concern

    included do

      # attribute :linked_resource_urls, multiple: true
      attr_accessor :linked_resource_urls

      has_many :linked_resources, property: :is_part_of, class_name:"Worthwhile::LinkedResource"

      after_destroy :after_destroy_cleanup_linked_resources
    end

    def after_destroy_cleanup_linked_resources
      linked_resources.each(&:destroy)
    end

  end
end

