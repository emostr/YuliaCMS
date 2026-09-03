#!/usr/bin/env ruby
# frozen_string_literal: true

# Checks that every internal link in the built documentation points at a file
# that actually exists.
#
# This exists because of a failure that was invisible from the inside: the site
# was published under a custom domain at the root, while Jekyll was configured
# with a path prefix. Every page still built, every page still loaded, and every
# single link on them was a 404. Nothing in the build said a word.
#
#   ruby scripts/check-links.rb _site
#
root = ARGV[0] || "_site"

unless Dir.exist?(root)
  abort "no such directory: #{root}"
end

broken = Hash.new { |hash, key| hash[key] = [] }
pages = Dir.glob(File.join(root, "**", "*.html"))
checked = 0

pages.each do |page|
  html = File.read(page)
  from = page.sub(root, "")

  html.scan(/(?:href|src)="([^"]+)"/).flatten.each do |link|
    # Only links this build is responsible for.
    next if link.start_with?("http://", "https://", "//", "data:", "mailto:", "#")

    path = link.split("#").first.to_s.split("?").first.to_s
    next if path.empty?

    checked += 1

    target = path.start_with?("/") ? File.join(root, path) : File.join(File.dirname(page), path)
    # A directory link is served by the index.html inside it.
    next if File.exist?(target) || File.exist?(File.join(target, "index.html"))

    broken[from] << link
  end
end

puts "checked #{checked} internal links across #{pages.size} pages"

if broken.empty?
  puts "all internal links resolve"
else
  puts "\nbroken links:"
  broken.each do |page, links|
    puts "  #{page}"
    links.uniq.each { |link| puts "    #{link}" }
  end
  exit 1
end
