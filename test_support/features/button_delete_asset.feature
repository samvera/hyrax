@delete
Feature: Button to delete assets
  In order delete assets
  As a person with permissions to the object
  I want to see an asset being deleted
  
  Scenario: Deleting a standard asset.
    Given I am logged in as "archivist1@example.com"
    When I am on the home page
    And I follow "Add a Basic MODS Asset"
    Then I should see "Created a Mods Asset with pid "
    When I press "Delete This Item"
    Then I should see "Deleted changeme:"
