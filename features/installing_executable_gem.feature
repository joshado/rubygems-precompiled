Feature: Installing using a compiled-cache

  Background:
    Given I have wiped the folder "/tmp/precompiled-workroot"

  Scenario: Installing a gem with an executable
    Given I use the gem configuration option
      """
      precompiled_cache:
       - file:///tmp/precompiled-workroot/cache
       """

    When I execute "gem precompile -o /tmp/precompiled-workroot/cache -a spec/fixtures/executable-gem.gem"

    And I execute "gem install --install-dir /tmp/precompiled-workroot/installroot spec/fixtures/executable-gem.gem"

    Then I should not see "Building native extensions"
    Then I should see "Loading native extension from cache"

    Then the extension file "executable-gem-0.0.1/executable_file" in "/tmp/precompiled-workroot/installroot" should have permissions "0755"
