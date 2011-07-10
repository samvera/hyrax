@permissions
Feature: Edit Permissions
  As a user with edit permissions
  In order to edit who has which levels of access to a document
  I want to see and edit the object-level permissions for users and groups

  Scenario: Viewing group & individual permissions
    Given I am logged in as "archivist1" 
    Given I am on the edit document page for hydrangea:fixture_mods_article1 
    Then the following should be selected within "form#permissions_metadata"
      |Archivist | Edit & Upload |
      |Researcher | No Access |
      |researcher1 | Edit & Upload |
      |Admin_policy_object_editor | No Access |
      |Public | Discover |
      
  Scenario: Editing group permissions on article edit page
    Given I am logged in as "archivist1" 
    And I am on the edit document page for hydrangea:fixture_mods_article1 
    And the following should be selected within "form#permissions_metadata"
      |Archivist | Edit & Upload |
      |researcher1 | Edit & Upload |
      |Admin_policy_object_editor | No Access |
      |Public | Discover |
    When I select the following within "form#permissions_metadata"
      |Archivist | Edit & Upload |
      |Admin_policy_object_editor | Discover |
      |Patron | Edit |
    And I press "Save Permissions"
    Then I should see "The permissions have been updated."
    And the following should be selected within "form#permissions_metadata"
      |Archivist | Edit & Upload |
      |Admin_policy_object_editor | Discover |
      |Patron | Edit |
  
  Scenario: Editing group permissions on permissions index page
    Given I am logged in as "archivist1" 
    And I am on the permissions page for hydrangea:fixture_mods_dataset1 
    When I select the following within "form#permissions_metadata"
      |Archivist | Edit & Upload |
      |Admin_policy_object_editor | Discover |
      |Patron | Edit |
    And I press "Save Permissions"
    Then I should see "The permissions have been updated."
    And the following should be selected within "form#permissions_metadata"
      |Archivist | Edit & Upload |
      |Admin_policy_object_editor | Discover |
      |Patron | Edit |
      
  Scenario: Viewing individual permissions with your own permissions hidden
    Given I am logged in as "researcher1" 
    And I am on the edit document page for hydrangea:fixture_mods_article1 
    ##
    ## This one fails because Capybara's selectors can't find "#individual_permissions" 
    ##
    # Then I should not see "researcher1" within "form#permissions_metadata"