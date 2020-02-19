module Hyrax::WithDepositor
  # Adds metadata about the depositor to the asset and
  # grants edit permissions to the +depositor+
  # @param [String, #user_key] depositor
  def apply_depositor_metadata(depositor)
    depositor_id = depositor.respond_to?(:user_key) ? depositor.user_key : depositor
    self.depositor = depositor_id if respond_to? :depositor
    Hyrax::AccessControlList.new(resource: self).grant(:edit).to(::User.find_by_user_key(depositor_id)).save
    true
  end
end
