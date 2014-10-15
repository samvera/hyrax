require 'spec_helper'

describe Hydra::AccessControls::AccessRight do
  [
    [false, Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,        nil,                                              nil,             true, false, false, false],
    [false, Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED, nil,                                              nil,             true, false, false, false],
    [false, nil,                                              nil,                                              nil,             true, false, false, false],
    [false, nil,                                              nil,                                              2.days.from_now, false, false, false, true],
    [false, nil,                                              nil,                                              2.days.ago,      false, false, false, true],
    [false, nil,                                              Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,        nil,             true, false, false, false],
    [false, nil,                                              Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, nil,             false, true, false, false],
    [false, nil,                                              Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,       nil,             false, false, true, false],
    [false, nil,                                              Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,       nil,             false, false, false, true],
    [true,  Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,        nil,                                              nil,             true, false, false, false],
    [true,  Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,        nil,                                              2.days.from_now, false, false, false, true],
    [true,  Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC,        nil,                                              2.days.ago,      false, false, false, true],
    [true,  Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED, nil,                                              nil,             false, true, false, false],
    [true,  nil,                                              nil,                                              nil,             false, false, true, false],
    [true,  nil,                                              Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,        nil,             true, false, false, false],
    [true,  nil,                                              Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, nil,             false, true, false, false],
    [true,  nil,                                              Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,       nil,             false, false, true, false],
    [true,  nil,                                              Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,       nil,             false, false, false, true],
  ].each do |given_persisted, givin_permission, given_visibility, given_embargo_release_date, expected_open_access, expected_authentication_only, expected_private, expected_open_access_with_embargo_release_date|
    spec_text = <<-TEXT

    GIVEN: {
      persisted: #{given_persisted.inspect},
      permission: #{givin_permission.inspect},
      visibility: #{given_visibility.inspect},
      embargo_release_date: #{given_embargo_release_date}
    },
    EXPECTED: {
      open_access: #{expected_open_access.inspect},
      restricted: #{expected_authentication_only.inspect},
      private: #{expected_private.inspect},
      open_access_with_embargo_release_date: #{expected_open_access_with_embargo_release_date}
    },
    TEXT

    it spec_text do
      permissions = if givin_permission
        [Hydra::AccessControls::Permission.new(type: 'group', access: 'edit', name: givin_permission)]
      else
        []
      end

      permissionable = double(
        'permissionable',
        permissions: permissions,
        visibility: given_visibility,
        persisted?: given_persisted,
        embargo_release_date: given_embargo_release_date
      )
      access_right = Hydra::AccessControls::AccessRight.new(permissionable)

      expect(access_right.open_access?).to eq(expected_open_access)
      expect(access_right.authenticated_only?).to eq(expected_authentication_only)
      expect(access_right.private?).to eq(expected_private)
      expect(access_right.open_access_with_embargo_release_date?).to eq(expected_open_access_with_embargo_release_date)
    end
  end
end
