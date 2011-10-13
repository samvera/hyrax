@pending @articles
Feature: Edit an article without permission
  As a logged-in user
  attempt to edit an article
  without sufficient permissions
  
  Scenario: Visit Document Edit Page
    Given I am logged in as "archivist1@example.com" 
    When I am on the edit document page for hydrangea:fixture_mods_article2
    Then I should see a "div" tag with a "class" attribute of "notice"

  Scenario: Authenticated but not Authorized to Edit
    Given I am logged in as "archivist1@example.com" 
    When I am on the edit document page for hydrangea:fixture_mods_article2
    Then the page should be HTML5 valid
