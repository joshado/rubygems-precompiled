Feature: Installing using a compiled-cache

  Background:
    Given I have wiped the folder "/tmp/precompiled-workroot"

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
      echo "puts CompiledClass.new.test_method" | ruby -I "/tmp/precompiled-workroot/installroot/extensions/x86_64-darwin-15/2.1.0-static/compiled-gem-0.0.1" -r "test_ext/test_ext"
      """

    Then I should see "Hello, world!"

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
      echo "puts CompiledClass.new.test_method" | ruby -I "/tmp/precompiled-workroot/installroot/extensions/x86_64-darwin-15/2.1.0-static/compiled-gem-0.0.1" -r "test_ext/test_ext"
      """

    Then I should see "Hello, world!"


