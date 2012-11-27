URLS = [
  'http://www.squaredancing.com/colorado/data/xml/areaClubs_NE.xml',
  'http://www.squaredancing.com/colorado/data/xml/areaClubs_DENVER.xml',
  'http://www.squaredancing.com/colorado/data/xml/areaClubs_SE.xml',
  'http://www.squaredancing.com/colorado/data/xml/areaClubs_WEST.xml'
]

EXCEPTIONS = {
  'Guys & Dolls' => {
    :directions => Proc.new { |d, c| c.delete(:address) }
  },
  'Ponderosa Promenaders' => {
    :directions => Proc.new { |d, c| r = /\((.+)\)\s*/; d = r.match(c[:address])[1]; c[:address].sub!(r, ''); d }
  },
  'Ridge Runners' => {
    :address => '26215 Sutton Road, Aspen Park, CO'
  },
  'Rocky Mountain Rainbeaus' => {
    :address => '809 South Washington Street, Denver, CO'
  },
  'High Country Squares' => {
    :address => '230 Port Avenue, Pagosa Springs, CO'
  },
  'Greenridge Mountaineers' => {
    :address => '1420 Ogden Street #103, Denver, CO'
  }
}

require 'time'
require 'open-uri'
require 'csv'
require 'nokogiri'
require 'colorize'
require 'pp'

clubs = []

URLS.each do |url|

  doc = Nokogiri::XML(open(url))
  doc.css('clubItem').each do |club|
    name = club.css('clubName').text
    rounds = name =~ /round/i
    level = club.css('danceLevel').text
    mainstream = level =~ /mainstream/i
    plus = level =~ /plus/i
    advanced = level =~ /advanced/i
    mainstream = true unless plus or advanced or rounds
    desc = club.css('clubDesc').text
    if desc =~ /((first|second|third|fourth|fifth|1st|2nd|3rd|4th|5th|every)\s*(&|and|,)?\s*)+\s*(other)?\s*(sun|mon|tues?|wed(nes)?|thur?s?|fri|sat(ur)?)(\.|day)?/i
      schedule = $~.to_s
    else
      schedule = nil
    end
    if schedule and desc =~ /([\d:\.apm]+\s*(to|\-)\s*)?\d\d?:\d\d(\s*a\.?m\.?|\s*p\.?m\.?)?|\d\d?\s*(a\.?m\.?|p\.?m\.?)/i
      if $1
        time = $1.sub(/(\-|to)\s*$/, '')
        time << ($3 || 'pm') unless time =~ /am|pm/i
      else
        time = $~.to_s
      end
      time = Time.parse(time).strftime('%H:%M')
    else
      time = nil
    end
    location = club.css('venueName').text
    address = (club.css('venueAddress1').text.strip + ', ' + club.css('venueAddress2').text.strip + ', ' + club.css('venueCity').text.strip + ', ' + club.css('venueState').text.strip).gsub(/, , /, ', ')
    address = nil if address =~ /^[ ,]*$|^, /
    state = club.css('venueState').text
    state = 'CO' if state.empty?
    if desc =~ /(caller|cuer):\s*([\w\s,\-&\/]+)/i
      caller = $2
    else
      caller = nil
    end
    contacts = club.css('clubContactInfo').text.scan(/(\d{3})[\) \-]+(\d{3}).(\d{4})/).map { |m| "(#{m[0]}) #{m[1]}-#{m[2]}" }.join(', ')
    website = club.css('webLink').text
    if not location.empty?
      clubs << {
        name: name,
        mainstream: mainstream,
        plus: plus,
        advanced: advanced,
        rounds: rounds,
        schedule: schedule,
        time: time,
        location: location,
        address: address,
        state: state,
        caller: caller,
        contacts: contacts,
        website: website
      }
    end
  end

end

clubs.each do |info|
  if exception = EXCEPTIONS[info[:name]]
    exception.each do |key, val|
      next if key == :pre
      if Proc === val
        val = val.call(info[key], info)
      end
      info[key] = val
    end
  end
end

CSV.open('co.csv', 'w') do |csv|
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
