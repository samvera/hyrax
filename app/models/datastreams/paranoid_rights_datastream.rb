require 'hydra/datastream/rights_metadata'
# subclass built-in Hydra RightsDatastream and build in extra model-level validation
class ParanoidRightsDatastream < Hydra::Datastream::RightsMetadata
  use_terminology Hydra::Datastream::RightsMetadata

  class PermissionsViolation < ::RuntimeError; end

  VALIDATIONS = {
    'Depositor must have edit access' => lambda { |obj| !obj.edit_users.include?(obj.depositor) },
    'Public cannot have edit access' => lambda { |obj| obj.edit_groups.include?('public') },
    'Registered cannot have edit access' => lambda { |obj| obj.edit_groups.include?('registered') }
  }

  def validate(object)
    VALIDATIONS.each do |message, error_condition|
      raise PermissionsViolation, message if error_condition.call(object)
    end
  end
end
