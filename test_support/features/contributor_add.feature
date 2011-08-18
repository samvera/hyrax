@edit @contributors
Feature: Add a Contributor
  In order to associate new people, organizations and conferences with an item
  As a person with edit permissions
  I want to add a new contributor

  # These are breaking with complaints that "Only get requests are allowed. (ActionController::MethodNotAllowed)"
  # This error only occurs in cucumber, not in real browser testing.

  @nojs
  Scenario: Add a person without javascript
    Given I am logged in as "archivist1@example.com"
    #When I am on the edit document page for hydrangea:fixture_mods_article1
    When I am on the edit contributor page for hydrangea:fixture_mods_article1
    And I press "Add Another Author"
    Then I should see "Your changes have been saved."
#    When I fill in the following:
    When I fill in "person_2_computing_id" with "098556"
    And I fill in "person_2_first_name" with "Myra"
    And I fill in "person_2_last_name" with "Breckenridge"
    And I fill in "person_2_description" with "Posture and Empathy"
    And I fill in "person_2_institution" with "Academy for Aspiring Young Actors and Actresses"
    And I press "Continue"
    Then I should see "Your changes have been saved."
    And I should see "Breckenridge"
#    Then I should see "The First and Last names are required for all authors."
    #    Then I should be on the edit document page for hydrus:test_object1
    #    And the following should contain:
    #    | Computing ID  | 098556 |
    #    | First Name    | Myra |
    #    | Last Name     | Breckenridge |
    #    | Department    | Posture and Empathy |
    #    | Institution   | Academy for Aspiring Young Actors and Actresses |
  
  # need to figure out the deal w/ organizations.  Not in spec.
#  @nojs
#  Scenario: Add an organization without javascript
#    Given I am logged in as "archivist1@example.com"
#    And I am on the edit document page for hydrangea:fixture_mods_article1
#    When I follow "Add an Organization"
#    And I fill in "Organization" with "American Film Academy"
    # And I press "Add Organization"
    # Then I should be on the edit document page for hydrus:test_object1
    # And the "Organization" field should contain "American Film Academy"
    