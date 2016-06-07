Given /this version of rubygems supports build options/ do
  require "rubygems/installer"
  unless Gem::Installer.method_defined?(:write_build_info_file)
    pending "This test will not pass on this version of rubygems."
  end
end
