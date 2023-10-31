require 'json'
require 'uri'
require 'httparty'
require 'pry'
require 'dotenv'

class Geocoding
  GEONAMES_URL = 'http://api.geonames.org/findNearbyPlaceNameJSON'.freeze
  DIST_ARR = { car: { min: 10, max: 300 }, walk: { min: 1, max: 10 }, bicycle: { min: 3, max: 30 } }.freeze
  MAX_ROWS = 30
  RESPONSE_STYLE = 'short'.freeze
  CITY_SIZES = %w[cities500 cities1000 cities5000 cities15000].freeze

  def init_vars(opts)
    Dotenv.load
    @size ||= opts.fetch('size', 2)
    @local ||= opts.fetch('local', true)
    @type ||= opts.fetch('type', :car).to_sym
    @radius ||= opts.fetch('radius', DIST_ARR[@type][:max])
    @radius = [@radius, 15].max
    @radius = [@radius, 300].min
    @rounds ||= opts.fetch('rounds', 1)
    @skiped ||= []
    # todo добавлять в пропуски первый город
    @route ||= []
    @geonames_user = ENV['GEONAMES_USER']
  end

  def gen_route(lat, lng, opts = {})
    init_vars(opts)
    next_city = choose_city(nearest_cities(lat, lng))
    raise "no next city: #{next_city} please use different parameters" unless next_city[:name]

    puts "Next city is #{next_city[:name]}"
    @route << next_city
    puts "current round is #{@rounds}"
    if @rounds == 1
      puts "\n\nМаршрут:"
      @route.each { |point| puts point[:name] }
      @route
    else
      @rounds -= 1
      # todo lat and lng use from prev city
      gen_route(lat, lng, size: @size, local: @local, radius: @radius, type: @type, cache: @route, skiped: @skiped_arr, rounds: @rounds)
    end
    rescue StandardError => e
      raise "something goes wrong in gen_route method: #{e.message}"
  end

  def nearest_cities(lat, lng)
    uri = URI(GEONAMES_URL)
    uri.query = URI.encode_www_form(
      lat: lat,
      lng: lng,
      style: RESPONSE_STYLE,
      cities: CITY_SIZES[@size],
      radius: @radius,
      maxRows: MAX_ROWS,
      username: @geonames_user,
      localCountry: @local,
    )
    response = HTTParty.get(uri.to_s)
    puts "url: #{uri.to_s}"
    JSON.parse(response.body, symbolize_names: true)
  rescue StandardError => e
    raise "something goes wrong in nearest_cities method: #{e.message}"
  end

  def choose_city(cities)
    arr = []
    puts "skipped cities: #{@skiped}"
    cities[:geonames].each do |city|
      if DIST_ARR[@type][:min] < city[:distance].to_f && city[:distance].to_f < @radius.to_f && !@skiped.include?(city)
        arr << city
      elsif DIST_ARR[@type][:min] > city[:distance].to_f && !@skiped.include?(city)
        @skiped << city
      end
    end
    arr.sample
  rescue StandardError => e
    raise "something goes wrong in choose_city method: #{e.message}"
  end
end
