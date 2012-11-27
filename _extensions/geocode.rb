require 'cgi'
require 'open-uri'
require 'json'

GEO_CACHE_PATH = File.expand_path('../../jekyll_geocache.json', __FILE__)
GEO_CACHE = JSON.parse(File.exist?(GEO_CACHE_PATH) ? File.read(GEO_CACHE_PATH) : '{}')

module Jekyll
  class Post
    alias_method :to_liquid_without_geocoding, :to_liquid
    def to_liquid
      to_liquid_without_geocoding.tap do |data|
        addr = data['address'].gsub(/&amp;/, '&') rescue nil # unencode
        if addr and not data['lat']
          loc = GEO_CACHE[addr]
          unless loc
            puts "geocoding address... #{addr}"
            result = JSON.parse(open("http://maps.googleapis.com/maps/api/geocode/json?address=#{CGI.escape addr}&sensor=false").read)
            loc = result['results'][0]['geometry']['location'] rescue 'none'
            GEO_CACHE[addr] = loc
            self.class.update_geo_cache!
          end
          data.merge!(loc) if loc != 'none'
        end
      end
    end

    def self.update_geo_cache!
      File.open(GEO_CACHE_PATH, 'w') { |f| f.write GEO_CACHE.to_json }
    end
  end
end
