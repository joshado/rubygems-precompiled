Feature: Pre-compiling gems

  Background:
    Given I have changed to a temporary directory containing "spec/fixtures/*.gem"

  Scenario: Input validation
    When I run the command "gem precompile"
    Then I should see "Please specify a gem file on the command line, e.g. gem precompile foo-0.1.0.gem"
    And the command should not return a success status code

  Scenario: Pre-compiling a single gem
    When I run the command "gem precompile simple-gem.gem"

    Then I should see "The gem 'simple-gem' doesn't contain a compiled extension"
    And the command should return a success status code

  Scenario: Pre-compiling a single compiled gem
    When I run the command "gem precompile compiled-gem.gem"

    Then I should see "Compiling 'compiled-gem'..."
    And the command should return a success status code

  Scenario: Pre-compiling multiple gems
    When I run the command "gem precompile *.gem"

    Then I should see "The gem 'simple-gem' doesn't contain a compiled extension"
    And I should see "Compiling 'compiled-gem'..."
    And I should see "done."
    And the command should return a success status code

  Scenario: Creating the flat output files
    When I run the command "gem precompile *.gem"

    Then the file "compiled-gem-0.0.1.tar.gz" should exist
    And the file "simple-gem*.tar.gz" should not exist

  Scenario: Writing to specific folder
    When I run the command "gem precompile -o foo *.gem"

    Then the folder "foo" should exist
    And the file "foo/compiled-gem-0.0.1.tar.gz" should exist

  Scenario: Creating architecture files
    When I run the command "gem precompile -o foo -a *.gem"

    Then the file "foo/ruby-*/x86_64-*/compiled-gem-0.0.1.tar.gz" should exist

