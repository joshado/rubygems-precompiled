require "tmpdir"
require 'fileutils'

When /^I run the command "(.*?)"$/ do |command|
  @last_stderr, @last_stdout = "", ""

  stderr_r, stderr_w, stdout_r, stdout_w = [IO.pipe, IO.pipe].flatten

  pid = spawn(command, :out => stdout_w, :err => stderr_w)
  _, status = Process.waitpid2(pid)

  [stderr_w,stdout_w].each { |p| p.close }

  @last_status = status.exitstatus
  @last_stderr += stderr_r.read until stderr_r.eof?
  @last_stdout += stdout_r.read until stdout_r.eof?
end

Then /^I should see "(.*?)"( on (stdout|stderr))?$/ do |expect, any, channel|
  data = if channel.nil?
    @last_stdout + @last_stderr
  elsif channel == 'stdout'
    @last_stdout
  elsif channel == 'stderr'
    @last_stderr
  end

  data.should include(expect)
end

Then /^the command should( not)? return a success status code$/ do |invert|
  if invert
    @last_status.should_not == 0
  else
    @last_status.should == 0
  end
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
