Feature: Installing using a compiled-cache

  Background:
    Given I have wiped the folder "/tmp/precompiled-workroot"

#  Scenario: Installing a compiled gem without the cache

  Scenario: Installing a compiled gem with a cache miss
    Given I use the gem configuration option
      """
      precompiled_cache:
       - file:///tmp/precompiled-workroot/cache
      """

    When I execute "gem install --install-dir /tmp/precompiled-workroot/installroot spec/fixtures/compiled-gem.gem"
    Then I should see "Building native extensions"
    Then I should not see "Loading native extension from cache"

    When I execute
      """
      echo "puts CompiledClass.new.test_method" | ruby -I/tmp/precompiled-workroot/installroot/gems/compiled-gem-0.0.1/lib -rtest_ext/test_ext
      """

    Then I should see "Hello, world!"

  # this works in reality but the test is dodgy on ruby 2. Needs investment in time to fix
  Scenario: Installing a compiled gem with a cache hit
    Given I use the gem configuration option
      """
      precompiled_cache:
       - file:///tmp/precompiled-workroot/cache
       """

    When I execute "gem precompile -o /tmp/precompiled-workroot/cache -a spec/fixtures/compiled-gem.gem"

    And I execute "gem install --install-dir /tmp/precompiled-workroot/installroot spec/fixtures/compiled-gem.gem"

    Then I should not see "Building native extensions"
    Then I should see "Loading native extension from cache"

    When I execute
      """
      echo "puts CompiledClass.new.test_method" | ruby -I/tmp/precompiled-workroot/installroot/gems/compiled-gem-0.0.1/lib -rtest_ext/test_ext
      """

    Then I should see "Hello, world!"


