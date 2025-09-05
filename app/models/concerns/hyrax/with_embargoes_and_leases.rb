# frozen_string_literal: true
module Hyrax
  module WithEmbargoesAndLeases
    extend ActiveSupport::Concern

    def embargo=(value)
      raise TypeError "can't convert #{value.class} into Hyrax::Embargo" unless value.is_a? Hyrax::Embargo

      @embargo = value
      self.embargo_id = @embargo.id
    end

    def embargo
      return @embargo if @embargo
      @embargo = Hyrax.query_service.find_by(id: embargo_id) if embargo_id.present?
    end

    def lease=(value)
      raise TypeError "can't convert #{value.class} into Hyrax::Lease" unless value.is_a? Hyrax::Lease

      @lease = value
      self.lease_id = @lease.id
    end

    def lease
      return @lease if @lease
      @lease = Hyrax.query_service.find_by(id: lease_id) if lease_id.present?
    end
  end
end
