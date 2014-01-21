
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
  cleanup.each { |dir| FileUtils.rm_rf(dir) }
end

Then /^the folder "(.*?)" should exist$/ do |folder|
  File.directory?(folder).should be_true
end

Then /^the file "(.*?)" should (not )?exist$/ do |file, invert|
  if invert
    Dir.glob(file).should be_empty
  else
    Dir.glob(file).should_not be_empty
  end
end
