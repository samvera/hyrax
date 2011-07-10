@create @split_button @add_asset
Feature: Button to Add Mods Assets
  In order to create Mods Assets
  As a person with submit permissions
  I want to see a button for adding MODS Assets
  
  Scenario: button to add articles on home page
    Given I am logged in as "archivist1"
    When I am on the home page
    When I follow "Add a Basic MODS Asset" 
    Then I should see "Created a Mods Asset with pid "
