@create @split_button @add_asset
Feature: Button to Add Generic Content
  In order to create Generic Content objects
  As a person with submit permissions
  I want to see a button for adding Generic Content
  
  Scenario: button to add articles on home page
    Given I am logged in as "archivist1"
    When I am on the home page
    When I follow "Add Generic Content" 
    Then I should see "Created a Generic Content with pid "
