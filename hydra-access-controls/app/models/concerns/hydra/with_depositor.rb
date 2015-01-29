module Hydra::WithDepositor
  # Adds metadata about the depositor to the asset and
  # grants edit permissions to the +depositor+
  # @param [String, #user_key] depositor
  def apply_depositor_metadata(depositor)
    depositor_id = depositor.respond_to?(:user_key) ? depositor.user_key : depositor

    if respond_to? :depositor
      self.depositor = depositor_id
    end
    self.edit_users += [depositor_id]
    true
  end
end
