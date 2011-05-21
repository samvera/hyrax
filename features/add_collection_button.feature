@create @split_button @overwritten
Feature: Create Collection Split Button
  In order to create new Collection
  As an admin_policy_editor 
  I want to see a button that will let me create a new Collection
  
  Scenario: Editor views the search results page and sees the add article button
    Given I am logged in as "archivist1" with "admin_policy_object_editor" permissions
    Given I am on the base search page
    Then I should see "Create new collection" within "div#select-item-box"
    And I should see "Add new item" within "div#select-item-box"
    
    
  Scenario: Non-editor views the search results page and does not see the add article button
    Given I am on the base search page
    Then I should not see "Add a collection" 
    And I should not see "Add an item"
  
