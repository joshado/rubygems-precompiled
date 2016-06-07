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
  $stderr.puts "Executing '#{command}'"
  @last_stderr, @last_stdout = "", ""

  stderr_r, stderr_w, stdout_r, stdout_w = [IO.pipe, IO.pipe].flatten
  @command_env ||= {}

  pid = spawn( @command_env, command, :out => stdout_w, :err => stderr_w)
  _, status = Process.waitpid2(pid)

  [stderr_w,stdout_w].each { |p| p.close }

  @last_status = status.exitstatus
  @last_stderr += stderr_r.read until stderr_r.eof?
  @last_stdout += stdout_r.read until stdout_r.eof?

  puts @last_stderr
end

When /^I (?:run ruby)$/ do |command|
  installroot = "/tmp/precompiled-workroot/installroot"
  extension_path = if Gem::Version.new(Gem::VERSION) < Gem::Version.new("2.0.0")
    "#{installroot}/gems/compiled-gem-0.0.1/lib"
  else
    "#{installroot}/extensions/#{Gem::Platform.local}/#{RbConfig::CONFIG["ruby_version"]}-static/compiled-gem-0.0.1"
  end

  cmd = %{cat <<RUBY | ruby -I "#{extension_path}"
#{command}
RUBY}
  execute(cmd)
  raise RuntimeError, "Command '#{command}' exited with non-zero exit status" unless @last_status == 0
end

When /^I (?:run the command|execute) "(.*?)"( ignoring the exit code)?$/ do |command, ignore_exit_code|
  execute(command)
  raise RuntimeError, "Command '#{command}' exited with non-zero exit status" unless ignore_exit_code or @last_status == 0
end

When /^I (?:run the command|execute)$/ do |command|
  execute(command)
  raise RuntimeError, "Command '#{command}' exited with non-zero exit status" unless @last_status == 0
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

Then /^the command should leave behind temporary directories/ do
  data = @last_stdout + @last_stderr
  data.each_line do |l|
    if m = l.match(/Leaving (.*) in place/)
      expect(Dir.exists?(m[1])).to be true
    end
  end
end

Then /^the command should( not)? return a success status code$/ do |invert|
  if invert
    @last_status.should_not == 0
  else
    @last_status.should == 0
  end
end
