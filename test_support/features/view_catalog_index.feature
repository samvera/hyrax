@catalog
Feature: Catalog Index
  As a user
  In order to find the documents I'm searching for
  I want to see my search results in an useful way.

  Scenario: Viewing search results
    Given I am on the catalog index page
    Then I should see "Search"

  Scenario: Executing a search
    Given I am on the catalog index page
    And I fill in "q" with "hydrangea"
    And I press "submit"
    Then I should see "Title"
    And I should see "Author"
    And I should see "Work"
    And I should see "Files"
