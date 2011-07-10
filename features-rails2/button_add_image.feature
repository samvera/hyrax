@create @split_button @add_asset
Feature: Button to Add Images
  In order to create Images
  As a person with submit permissions
  I want to see a button for adding Images
  
  Scenario: button to add articles on home page
    Given I am logged in as "archivist1"
    When I am on the home page
    When I follow "Add an Image" 
    Then I should see "Created a Generic Image with pid "