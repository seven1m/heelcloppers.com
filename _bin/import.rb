#!/usr/bin/env ruby

require 'csv'
require 'date'
require 'time'
require 'erb'
require 'fileutils'
require 'open-uri'

CSV_URL = 'https://docs.google.com/spreadsheet/pub?key=0AniDuk4-exxodEF5TnF1MU1IYlRnaFNGTlhjWTktUVE&single=true&gid=0&output=csv'
OUT_PATH = File.expand_path('../../_posts', __FILE__)
DATE = '2012-01-17'
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
address: <%= club['Address'] %>
directions: <%= club['Directions'] %>
caller: <%= club['Caller'] %>
contact: <%= club['Contact'] %>
website: <%= club['Website'] %>
<% if club['Lat'] %>lat: <%= club['Lat'] %><% end %>
<% if club['Lng'] %>lng: <%= club['Lng'] %><% end %>

---

END

CSV.parse(open(CSV_URL).read, :headers => true).each_entry do |club|
  filename = "#{DATE}-#{club['Name'].scan(/[a-z0-9\-]+/i).join('-').downcase}.md"
  file_path = File.join(OUT_PATH, filename)
  if club['Status'] == 'inactive'
    FileUtils.rm(file_path) if File.exist?(file_path)
  else
    puts "#{club['Name']} => #{filename}"
    File.open(file_path, 'w') do |file|
      html = ERB.new(TEMPLATE).result(binding)
      file.write(html.gsub(/& /, '&amp; '))
    end
  end
end
