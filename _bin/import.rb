#!/usr/bin/env ruby

require 'csv'
require 'date'
require 'time'
require 'erb'

OUT_PATH = File.expand_path('../../_posts', __FILE__)
DATE = '2012-01-17'
FORCE = ARGV.delete('-f')
TEMPLATE = <<-END
---

layout: club
title: <%= club['Name'] %>
mainstream: <%= club['M'] %>
plus: <%= club['P'] %>
advanced: <%= club['A'] %>
rounds: <%= club['R'] %>
schedule: <%= club['Schedule'] %><% if club['Time'] %>,<%= Time.parse(club['Time']).strftime(' %I:%M %p').sub(/^ 0/, ' ') %><% end %>
location: <%= club['Location'] %>
caller: <%= club['Caller'] %>
contact: <%= club['Contact'] %>
website: <%= club['Website'] %>
<% if club['Lat'] %>lat: <%= club['Lat'] %><% end %>
<% if club['Lng'] %>lng: <%= club['Lng'] %><% end %>

---

END

CSV.parse(File.read(ARGV.first), :headers => true).each_entry do |club|
  filename = "#{DATE}-#{club['Name'].scan(/[a-z\-]+/i).join('-').downcase}.md"
  file_path = File.join(OUT_PATH, filename)
  if File.exist?(file_path) and not FORCE
    puts "File #{filename} exists. Use -f to force overwrite."
  else
    puts "#{club['Name']} => #{filename}"
    File.open(file_path, 'w') do |file|
      html = ERB.new(TEMPLATE).result(binding)
      file.write(html.gsub(/& /, '&amp; '))
    end
  end
end
