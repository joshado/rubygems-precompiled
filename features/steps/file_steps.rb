
Given /^I have wiped the folder "(.*?)"$/ do |path|
  FileUtils.rm_rf(path)
end


OriginalWorkingDirectory = Dir.pwd
Before do
  FileUtils.chdir(OriginalWorkingDirectory)
end
cleanup = []
Given /^I have changed to a temporary directory(?: containing "(.*?)")?$/ do |glob|
  directory = Dir.mktmpdir
  cleanup << directory
  if glob
    files = Dir.glob(glob)
    files.each do |file|
      FileUtils.cp(file, File.join(directory, File.basename(file)))
    end
  end
  FileUtils.chdir(directory)
end
After do
  FileUtils.chdir(OriginalWorkingDirectory)
  cleanup.each { |dir| FileUtils.rm_rf(dir) }
end

Then /^the folder "(.*?)" should exist$/ do |folder|
  expect(File.directory?(folder)).to be true
end

Then /^the file "(.*?)" should (not )?exist$/ do |file, invert|
  if invert
    Dir.glob(file).should be_empty
  else
    Dir.glob(file).should_not be_empty
  end
end

Then /^the extension file "(.*?)" in "(.*?)" should have permissions "(.*?)"$/ do |file, install_root, permissions|
  fullpath = "#{install_root}/extensions/#{Gem::platforms[1].to_s}/#{Gem::extension_api_version}/#{file}"
  expect(File.stat(fullpath).mode % 512).to eq permissions.to_i(8)
end
