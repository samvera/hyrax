@create @split_button @overwritten
Feature: Create Asset or Dataset Split Button
  In order to create new Assets or Datasets
  As an editor 
  I want to see a button that will let me create a new Article or Dataset
  
  # Hydrus does not have an "Add an article" button.  Marked entire feature _and_ individual scenarios @overwritten
  
  @overwritten
  Scenario: Editor views the search results page and sees the add article button
    Given I am logged in as "archivist1" 
    Given I am on the base search page
    Then I should see "Add an Article" within "ul li"
    
  # FOR CORE
  @overwritten
  Scenario: Non-editor views the search results page and does not see the add article button
   Given I am on the base search page
   Then I should not see "Add an Article" 

  
