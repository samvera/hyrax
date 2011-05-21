@create @split_button @add_asset
Feature: Create Asset or Dataset Split Button
  In order to create new Assets or Datasets
  As an editor 
  I want to see a button that will let me create a new Article or Dataset
  
  Scenario: Editor views the search results page and sees the buttons to add assets
    Given I am logged in as "archivist1" 
    Given I am on the base search page
    Then I should see "Add a Basic MODS Asset" within "ul li"
    Then I should see "Add an Image" within "ul li"
    Then I should see "Add Generic Content" within "ul li"
    

  Scenario: Non-editor views the search results page and does not see the buttons to add assets
   Given I am on the base search page
   Then I should not see "Add a Basic MODS Asset"
   Then I should not see "Add an Image" 
   Then I should not see "Add Generic Content"
