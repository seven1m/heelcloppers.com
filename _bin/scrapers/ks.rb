URL = 'http://www.kansassquaredance.com/State-Clubs.html'

EXCEPTIONS = {
  'Tnt' => {
    name: 'TNT'
  },
  'Kansas City' => {
    name: 'Kansas City (KC) Plus'
  },
  "Dj's Plus" => {
    name: "DJ's Plus"
  },
  "Fun 'N Rounds" => {
    schedule: "every other Sunday"
  },
  "Merry-Go-Rounders" => {
    schedule: 'some Sundays'
  },
  '4-Corners' => {
    schedule: 'every Saturday (except May-Sept)'
  },
  'Kuntry Kuzzins' => {
    schedule: '4th Friday (2nd Wednesday in Sept)'
  },
  'Shawnee Swingers' => {
    schedule: '4th Friday'
  },
  'St. Joe Squares' => {
    pre: Proc.new { |d| d.delete_at(1); d },
    schedule: '1st & 3rd Friday',
    address: '3524 St. Joseph Ave., St. Joseph, MO'
  },
  "Swingin' Singles" => {
    schedule: Proc.new { |s| s.split('day').first + 'day' }
  },
  "Wheatheart Squares" => {
    schedule: Proc.new { |s| s.sub(/Commencing.*$/, '') }
  },
  'Camping Squares of Kansas' => {
    schedule: 'Sept. 2nd Sat.; Dec. 1st Sun'
  },
  'Westside Steppers' => {
    schedule: Proc.new { |s| s.split('day').first + 'day' }
  },
  'Council Grove Squares' => {
    pre: Proc.new { |d| d.insert(1, 'Council Grove') }
  },
  'Classics' => {
    pre: Proc.new { |d| d.insert(1, 'Wichita') }
  }
}

require 'time'
require 'open-uri'
require 'csv'
require 'pp'

clubs = open(URL).read.scan(/<div[^>]*>[^<]*<font.*?>([^<]+)/i).map do |club|
  if club[0] =~ /^[A-Z\.\-\d]{2,}/ and club[0].length > 25
    data = club[0].gsub(/&#8217;|&#8216;/, "'").gsub(/&#160;/, ' ').gsub(/\s+/, ' ').gsub(/&amp;/, '&').split(/,\s*/)
    name = data[0]
    rounds = name =~ /\(.*round/i
    clogging = name =~ /\(.*clog/i
    contra = name =~ /\(.*contra/i
    plus = name =~ /\(.*plus/i
    advanced = name =~ /\(.*advance/i
    mainstream = true unless rounds or clogging or contra
    if rounds or plus or advanced
      name.gsub!(/\s*\(.*\)\s*/, '')
    end
    name = name.split(/\s+/).map { |w| w =~ /^([A-Z]\.)+$|'N/ ? w.upcase : w.capitalize }.join(' ').split('-').map { |w| w[0].upcase + w[1..100] }.join('-').gsub(/ Of /, ' of ').sub(/\(.* Dance\)/) { |m| m.to_s.downcase }
    if data and EXCEPTIONS[name] and p = EXCEPTIONS[name][:pre]
      data = p.call(data)
    end
    schedule = data.grep(/Sun|Mon|Tue|Wed|Thu|Fri|Sat/)
    if schedule.length > 1
      schedule = schedule.grep(/&/).first
    else
      schedule = schedule.first
    end
    if schedule
      schedule = schedule.gsub(/Sun\.?/, 'Sunday').gsub(/Mon\.?/, 'Monday').gsub(/Tues?\.?/, 'Tuesday').gsub(/Wed\.?/, 'Wednesday').gsub(/Thu(rs)?\.?/, 'Thursday').gsub(/Fri\.?/, 'Friday').gsub(/Sat\.?/, 'Saturday').gsub(/&/, ' & ').gsub(/\s+/, ' ').gsub(/Every|Other|First|Second|Third|Fourth/) { |m| m.downcase }.gsub(/\(check calendar.*\)/i, '').strip
    end
    if time = club[0].scan(/(\d+(:\d+)?\s*(am|pm))/i).map(&:first).first
      time = Time.parse(time).strftime('%H:%M')
    end
    location = data[2]
    address = data[3] + ', ' + data[1] + ', KS'
    caller = nil
    contacts = club[0].scan(/(\d{3})[\) \-]+(\d{3}).(\d{4})/).map { |m| "(#{m[0]}) #{m[1]}-#{m[2]}" }.join(', ')
    {
      name: name,
      mainstream: mainstream,
      plus: plus,
      advanced: advanced,
      rounds: rounds,
      schedule: schedule,
      time: time,
      location: location,
      address: address,
      caller: caller,
      contacts: contacts
    }
  end
end.compact

clubs.each do |info|
  if exception = EXCEPTIONS[info[:name]]
    exception.each do |key, val|
      next if key == :pre
      if Proc === val
        val = val.call(info[key])
      end
      info[key] = val
    end
  end
end

CSV.open('ks.csv', 'w') do |csv|
  csv << %w(Name M P A R Location Address Directions Lat Lng Schedule Time Contact Caller Website Status)
  clubs.each do |club|
    csv << [
      club[:name],
      club[:mainstream] ? 'yes' : 'no',
      club[:plus] ? 'yes' : 'no',
      club[:advanced] ? 'yes' : 'no',
      club[:rounds] ? 'yes' : 'no',
      club[:location],
      club[:address],
      nil,
      nil,
      nil,
      club[:schedule],
      club[:time],
      club[:contacts],
      club[:caller]
    ]
  end
end
