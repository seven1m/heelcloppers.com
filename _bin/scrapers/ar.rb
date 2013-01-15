URL = 'http://www.assdf.com/clubs.htm'

EXCEPTIONS = {
  'Twirling Funtimers' => {
    schedule: Proc.new { |s| s.split(',').first }
  },
  'Star Steppers' => {
    schedule: 'every Monday',
    address: Proc.new { |a| a << ', Pine Bluff, AR' }
  },
  'Skokos Promenaders' => {
    address: '19 East Kibler Highway, Alma, AR'
  }
}

require 'time'
require 'open-uri'
require 'csv'
require 'pp'

names = {}
clubs = open(URL).read.split('<hr>').map do |club|
  name = /Name.*: ([^<]*)/.match(club)
  if name
    next if names[name[1]]
    names[name[1]] = true
  end
  if level = /Level.*: ([^<]*)/.match(club)
    mainstream = level[1] =~ /mainstream/i
    plus = level[1] =~ /plus/i
    advanced = level[1] =~ /advanced/i
    rounds = level[1] =~ /round/i
  end
  if date_time = /When.*: (.*) at ([\d:apm]*)/.match(club)
    schedule = date_time[1].gsub(/Every/, 'every').gsub(/,? and /, ' & ').gsub(/days/, 'day').split(/workshop|meal|class/i).first.gsub(/[,\.]\s*$/, '').strip
    if schedule =~ /^(Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday)/
      schedule = "every #{schedule}"
    end
    time = Time.parse(date_time[2]).strftime('%H:%M')
  end
  place = /Where.*: ([^<]*)/.match(club)
  city = /City.*: ([^<]*)/.match(club)
  if place
    location, address = place[1].split(',', 2)
    if address
      address = address.gsub(/\(\s*$/, '').strip
      if address !~ /AR/ and city
        address << ', ' + city[1] + ', AR'
      end
    end
  end
  caller = /Caller.*: ([^<]*)/.match(club)
  contact = /Contact.*: ([^<]*)/.match(club)
  contacts = contact ? contact[1].scan(/(\d{3})[\) \-]+(\d{3}).(\d{4})/).map { |m| "(#{m[0]}) #{m[1]}-#{m[2]}" }.join(', ') : nil
  if name and date_time and place
    {
      name: name[1],
      mainstream: mainstream,
      plus: plus,
      advanced: advanced,
      rounds: rounds,
      schedule: schedule,
      time: time,
      location: location,
      address: address,
      state: 'AR',
      caller: caller ? caller[1] : nil,
      contacts: contacts
    }
  end
end.compact

clubs.each do |info|
  if exception = EXCEPTIONS[info[:name]]
    exception.each do |key, val|
      if Proc === val
        val = val.call(info[key])
      end
      info[key] = val
    end
  end
end

CSV.open('ar.csv', 'w') do |csv|
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
