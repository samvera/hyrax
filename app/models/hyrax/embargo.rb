module Hyrax
  class Embargo < Valkyrie::Resource
    attribute :id, Valkyrie::Types::ID.optional
    attribute :visibility_during_embargo, Valkyrie::Types::SingleValuedString
    attribute :visibility_after_embargo, Valkyrie::Types::SingleValuedString
    attribute :embargo_release_date, Valkyrie::Types::Set.member(Valkyrie::Types::DateTime).optional
    attribute :embargo_history, Valkyrie::Types::Set

    def active?
      (embargo_release_date.present? && Time.zone.today < embargo_release_date.first)
    end

    # Deactivates the embargo by nullifying all properties and logs a message
    # to the embargo_history property
    def deactivate
      return unless embargo_release_date
      embargo_state = active? ? "active" : "expired"
      embargo_record = embargo_history_message(embargo_state, Time.zone.today, embargo_release_date, visibility_during_embargo, visibility_after_embargo)
      self.embargo_release_date = nil
      self.visibility_during_embargo = nil
      self.visibility_after_embargo = nil
      self.embargo_history += [embargo_record]
    end

    private

      # Create the log message used when deactivating an embargo
      # This method may be overriden in order to transform the values of the passed parameters.
      def embargo_history_message(state, deactivate_date, release_date, visibility_during, visibility_after)
        I18n.t 'hydra.embargo.history_message', state: state, deactivate_date: deactivate_date, release_date: release_date,
                                                visibility_during: visibility_during, visibility_after: visibility_after
      end
  end
end
