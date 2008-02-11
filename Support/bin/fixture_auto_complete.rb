#!/usr/bin/env ruby

require 'rails_bundle_tools'
require 'yaml'
require File.join(ENV['TM_SUPPORT_PATH'], "lib", "escape")
DIALOG = ENV['DIALOG']

def parse_line
  current_line = TextMate.current_line
  line_parts = current_line.split(":")
  line_parts.map { |p| p.strip }
end

def load_referenced_fixture_file(ref)
  ref_plural = Inflector.pluralize(ref)
  ref_file = File.join(TextMate.project_directory, "test", "fixtures", "#{ref_plural}.yml")
  if (!File.exist?(ref_file))
    puts "Could not find any #{ref} fixtures."
    TextMate.exit_show_tool_tip
  end
  YAML.load_file(ref_file)
end

def ask_for_fixture_or_exit(fixtures)
  require "#{ENV['TM_SUPPORT_PATH']}/lib/osx/plist"
  h = fixtures.map do |f|
    {'title' => f, 'fixture' => f}
  end
  pl = {'menuItems' => h}.to_plist
  res = OSX::PropertyList::load(`#{e_sh DIALOG} -up #{e_sh pl}`)
  TextMate.exit_discard unless res.has_key? 'selectedMenuItem'
  res['selectedMenuItem']['fixture']
end

def filter_fixtures(fixtures, filter)
  if !filter.empty? && ARGV[0] != "preserve"
    fixtures.select do |f|
      f.include? filter
    end
  else
    fixtures
  end
end

ref, filter = parse_line
filter = "" if filter.nil?
foreign_fixtures = load_referenced_fixture_file(ref).keys
candidates = filter_fixtures(foreign_fixtures, filter)
if candidates.empty?
  puts "No match found for #{filter}"
  TextMate.exit_show_tool_tip
end
selected_fixture = ask_for_fixture_or_exit(candidates)

if ARGV[0] == "preserve"
  print TextMate.current_line.rstrip
  if !filter.empty?
    print ", "
  else
    print " "
  end
  print selected_fixture
else
  print "  #{ref}: #{selected_fixture}"
end
