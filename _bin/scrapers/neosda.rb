require 'open-uri'
require 'csv'

html = open('http://www.nesquaredance.com/clubinfo.html').read

clubs = []
club = nil
data = html.split('CLUBS', 2).last.gsub(/<[^>]+>/, '').gsub(/\r?\n|\t/, ' ').gsub(/&nbsp;/, ' ').gsub(/\s+/, ' ')
data.each_char.each_with_index do |char, index|
  if data[index..(index + 2)] =~ /^[A-Z\-]{3}$/ and (club.nil? || club.size > 25)
    clubs << club if club
    club = ''
  end
  club << char if club
end

clubs.map! do |string|
  string.gsub!(/&amp;/, '&')
  dashes = string.split(/\s+\-\s+/)
  styles = dashes[1].scan(/[A-Z]/)
  location = dashes.grep(/, OK|, AR|, KS|, MO|Tulsa/).first.split(/\s*;\s*/).grep(/, OK|, AR|, KS|, MO|Tulsa/).first rescue ''
  location.gsub!(/Tulsa/, 'Tulsa, OK') unless location =~ /, OK|, AR|, KS|, MO/
  website = string.match(/\w\w\w\.[a-z\.\-]+/).to_s
  callers = string.split(/\s*;\s*/).grep(/caller/i)[0].sub(/\s*,\s*Callers?/, '').strip rescue ''
  {
    name: dashes.first.gsub(/[A-Z]+/) { |m| "#{m[0]}#{m[1..-1].downcase}" },
    mainstream: styles.include?('M'),
    plus: styles.include?('P'),
    advanced: styles.include?('A'),
    rounds: styles.include?('R'),
    location: location.split(/\s*(,| at )\s*/).first,
    address: location.split(/\s*(,| at )\s*/, 2).last,
    state: location.match(/OK|AR|KS|MO/).to_s,
    directions: nil,
    schedule: string.split(/\s*;\s*/).grep(/Sun|Mon|Tue|Wed|Thu|Fri|Sat/)[0].split(/\(/).first,
    time: string.match(/\d+:\d+ (AM|PM)/)[0],
    contacts: string.scan(/\(\d{3}\) \d{3}\-\d{4}/).join(', '),
    caller: callers,
    website: website != '' ? "http://#{website}" : nil,
    string: string,
    location_str: location
  }
end

CSV.open('neosda.csv', 'w') do |csv|
  csv << %w(Name M P A R Location Address State Directions Lat Lng Schedule Time Contact Caller Website Status)
  clubs.each do |club|
    csv << [
      club[:name],
      club[:mainstream] ? 'yes' : 'no',
      club[:plus] ? 'yes' : 'no',
      club[:advanced] ? 'yes' : 'no',
      club[:rounds] ? 'yes' : 'no',
      club[:location],
      club[:address],
      club[:state],
      club[:directions],
      nil,
      nil,
      club[:schedule],
      club[:time],
      club[:contacts],
      club[:caller],
      club[:website]
    ]
  end
end
