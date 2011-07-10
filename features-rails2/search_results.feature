@pending @catalog
Feature: Search Results
  As a user
  In order to find the documents I'm searching for
  I want to see my search results in an useful way.

  Scenario: Viewing search results
    Given I am on the search results page
    When I have searched for "Artificial Intelligence"
    And I am in "List view" mode
    Then I should "List View" in highlight
    And I should see "gallery view" not in highlight 
    And I should see "search breadcrumb"
