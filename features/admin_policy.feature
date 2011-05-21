Feature: admin policy administration
  As a policy administrator
  I want to be able to administer my policies
  So I need proper access

@wip @local
Scenario: Login and permissions check
  Given I am logged in as "archivist1" with "admin_policy_object_editor" permissions
  Then I should see "something"
