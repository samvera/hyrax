Feature: Generic Image Create View
  I want to see appropriate information for creating generic image objects

  Scenario: html5 valid
    Given I am logged in as "archivist1"
    And I create a new generic_image
    Then the page should be HTML5 valid
