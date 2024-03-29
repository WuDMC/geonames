require 'json'
require 'uri'
require 'httparty'
require 'pry'
require 'dotenv'
# require_relative 'trip_roulette'
#   geocoding_instance = Geocoding.new
#   result = geocoding_instance.gen_route(lat, lng, opts)
# lat = 37.3967587
# lng =  -5.9893804

class Geocoding
  GEONAMES_URL = 'http://api.geonames.org/findNearbyPlaceNameJSON'.freeze
  DIST_ARR = { car: { min: 2, max: 300 }, walk: { min: 1, max: 5 }, bicycle: { min: 1, max: 15 } }.freeze
  MAX_ROWS = 500
  RESPONSE_STYLE = 'short'.freeze
  CITY_SIZES = %w[cities500 cities1000 cities5000 cities15000].freeze

    def initialize
        Dotenv.load
    end

  def init_vars(opts)
    @start_opts ||= opts
    puts "start opts #{@start_opts}"
    puts "opts #{opts}"
    @random ||= opts['random'] ? opts['random'] :  false
    @local ||= @random ? [false, true].sample : opts['local'] ? opts['local'] : [false, true].sample
    @rounds ||= @random ? rand(2..7) : opts['rounds'] ? opts['rounds'] : rand(2..7)
    @skiped ||= []
    # todo добавлять в пропуски первый город ???  зачем ? я не помню чтобы на круг не заходил
    @route ||= []
    @size = @random ? rand(0..3) : opts['size'] ? opts['size'] : rand(0..3)
    @type = @random ?  DIST_ARR.keys.sample : opts['type'] ? opts['type'].to_sym : DIST_ARR.keys.sample
    @radius = @random ? rand(DIST_ARR[@type][:min]..DIST_ARR[@type][:max]) : opts['radius'] ? opts['radius'] : rand(DIST_ARR[@type][:min]..DIST_ARR[@type][:max])
    @radius = [@radius, 2].max
    @radius = [@radius, 300].min
    @geonames_user = ENV['GEONAMES_USER']
    puts '_____________'
    puts '_____________'
    puts " opts: "\
         " @size: #{@size} "\
         " @local: #{@local} "\
         " @type: #{@type} "\
         " @radius #{@radius} "\
         " @rounds: #{@rounds} "\
         " @skiped: #{@skiped} "
    puts '_____________'
    puts '_____________'
  end

  def gen_route(lat, lng, opts = {})
    init_vars(opts)
    next_city = choose_city(nearest_cities(lat, lng))
    unless next_city
        puts "no next city: please use different parameters"
        return @route unless @random

        puts "AUTO USE NEW GENERATION WITH RANDOM OPTIONS"
        return gen_route(lat, lng, 'cache' => @route, 'skiped' => @skiped, 'rounds' => @rounds)
    end
    puts "Next city is #{next_city[:name]}"
    @route << next_city
    puts "current round is #{@rounds}"
    if @rounds == 1
      puts "\n\nМаршрут:"
      @route.each { |point| puts point[:name] }
      @route
    else
      puts "route last is #{@route[-1]}"
      lat = @route[-1][:lat]
      lng = @route[-1][:lng]
      @rounds -= 1
      # todo lat and lng use from prev city
      if @random
        puts 'random generation '
        gen_route(lat, lng, 'cache' => @route, 'skiped' => @skiped, 'rounds' => @rounds)
      else
        puts 'generation with attributes'
        gen_route(lat, lng, 'size' => @size, 'local' => @local, 'radius' => @radius, 'type' => @type, 'cache' => @route, 'skiped' => @skiped, 'rounds' => @rounds)
      end
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
    raise "something goes wrong url: #{uri.to_s} in nearest_cities method: #{e.message}"
  end

  def choose_city(cities)
    arr = []
    puts "skipped cities: #{@skiped}"
    cities[:geonames].each do |city|
      next if @skiped.include?(city[:toponymName])

      if DIST_ARR[@type][:min] < city[:distance].to_f && city[:distance].to_f < @radius.to_f &&
       !@skiped.include?(city[:toponymName])
        arr << city
      elsif DIST_ARR[@type][:min] > city[:distance].to_f && !@skiped.include?(city)
        puts "#{city[:toponymName]} is too close ? distance is #{city[:distance]} NEED TO SKIP"
        @skiped << city[:toponymName]
      end
    end
    return nil unless arr.any?

    # Сортируем массив arr по расстоянию от большему к меньшему
    arr_sorted = arr.sort_by { |city| city[:distance].to_f }.reverse
    puts "ARR SIZE #{arr_sorted.size}"
    # Вычисляем индекс, который представляет середину массива (50%)
    middle_index = (arr_sorted.length / 3.0).ceil
    puts "middle_index #{middle_index}"

    # Выбираем первую половину элементов отсортированного массива
    top_50_percent = arr_sorted.take(middle_index)
    puts "top_50_percent #{top_50_percent}"

    # Выбираем случайный город из топ 50% городов
    next_city = top_50_percent.sample
    puts '=============================='

    puts '=============================='

    puts '=============================='
    puts "#{arr_sorted[0][:distance]}"
    puts "#{arr_sorted[-1][:distance]}"

    puts "NEXT CITY: #{next_city}"
    @skiped << next_city[:toponymName]
    puts '=============================='

    puts '=============================='

    puts '=============================='
    next_city
  rescue StandardError => e
    raise "something goes wrong in choose_city method: #{e.message}"
  end
end
