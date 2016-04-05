# Rubygems::Precompiled

This gem allows you to build the c-extensions of a ruby-gem on a host with build-tools installed, make the result available over HTTP, then use this on end machines that may not have build-tools installed.

## Installation

    $ gem install rubygems-precompiled

## Usage

There are two halves to this, the pre-compile on a build machine and the install
on machines that don't have the build-tools available.

### Build host

Fetch a gem you're interested in:

    gem fetch foobar -v '0.1.0'

Pre-compile the gem into the correct folder structure:

    gem precompile -a -o /output foobar-0.1.0.gem

Which will write the file:

    /output/ruby-1.9.3p448/x86_64-linux/foobar-0.1.0.tar.gz

You need to make this directory structure available over HTTP, and available to the installation machines.

### Installation host

Configure the cache path (file:/// and http:// urls are supported at the moment) in `/etc/gemrc`:

    precompiled_cache:
     - http://some.server/ruby-gem-extensions/

Install a gem using the cache:

    gem install foobar -v '0.1.0'

### Running the tests

There are a couple of simple cucumber specs that exercise the plugin via the current version of rubygems. You can run them via:

    bundle
    bundle exec cucumber

When doing this, ensure you don't have either the simple_gem or compiled_gem installed locally, as this will inevitably confuse poor rubygems.

#### Fixture gems
The sources to build the gems used in the test are included in the gem-sources.tar.gz file in the fixtures directory. If you need to change these you will have to extract
the file modify the sources and re-create the .tar.gz archive, as well as putting the new gems in place in the fixtures directory.

