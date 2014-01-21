require "tmpdir"
require 'fileutils'
require 'tempfile'

Given /^I use the gem configuration option$/ do |string|
  File.open(File.expand_path("~/.gemrc"), "a") do |gemconfig|
    gemconfig.puts("# --PURGE FROM HERE ---")
    gemconfig.write string
  end

end
After do
  original, _ = File.read(File.expand_path("~/.gemrc")).split("# --PURGE FROM HERE ---")
  File.open(File.expand_path("~/.gemrc"), "w") do |gemconfig|
    gemconfig.write original
  end
end

def execute(command)
    @last_stderr, @last_stdout = "", ""

  stderr_r, stderr_w, stdout_r, stdout_w = [IO.pipe, IO.pipe].flatten
  @command_env ||= {}

  pid = spawn( @command_env, command, :out => stdout_w, :err => stderr_w)
  _, status = Process.waitpid2(pid)

  [stderr_w,stdout_w].each { |p| p.close }

  @last_status = status.exitstatus
  @last_stderr += stderr_r.read until stderr_r.eof?
  @last_stdout += stdout_r.read until stdout_r.eof?
end

When /^I (?:run the command|execute) "(.*?)"$/ do |command|
  execute(command)
end
When /^I (?:run the command|execute)$/ do |command|
    execute(command)
end

Then /^I should( not)? see "(.*?)"( on (stdout|stderr))?$/ do |invert, expect, any, channel|
  data = if channel.nil?
    @last_stdout + @last_stderr
  elsif channel == 'stdout'
    @last_stdout
  elsif channel == 'stderr'
    @last_stderr
  end

  if invert
    data.should_not include(expect)
  else
    data.should include(expect)
  end
end

Then /^the command should( not)? return a success status code$/ do |invert|
  if invert
    @last_status.should_not == 0
  else
    @last_status.should == 0
  end
end
