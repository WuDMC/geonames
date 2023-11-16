require 'sinatra'
require 'sinatra/cross_origin'
require 'json'
require_relative 'trip_roulette'

configure do
  set :geocoding_instance, Geocoding.new
  enable :cross_origin
end

set :bind, '0.0.0.0'

before do
  allowed_origins = ['http://localhost:8000', 'http://127.0.0.1:8000']

  origin = request.env['HTTP_ORIGIN']

  if allowed_origins.include?(origin)
    response.headers['Access-Control-Allow-Origin'] = origin
    response.headers['Access-Control-Allow-Methods'] = 'POST'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
  end
end


get '/' do
  "Hi, please send to '/route' path a POST request with the required parameters. \n curl -X POST http://localhost:4567/route -H 'Content-Type: application/json' -d '{\"lat\": -8.670458199999999, \"lng\": 115.2126293, \"opts\": {\"size\": 2, \"local\": true, \"radius\": 100, \"type\": \"car\", \"rounds\": 5}}"
end

get '/route' do
  "Hi, please send here a POST request with the required parameters. \n curl -X POST http://localhost:4567/route -H 'Content-Type: application/json' -d '{\"lat\": -8.670458199999999, \"lng\": 115.2126293, \"opts\": {\"size\": 2, \"local\": true, \"radius\": 100, \"type\": \"car\", \"rounds\": 5}}"
end

post '/route' do
  content_type :json
  request_payload = JSON.parse(request.body.read)
  lat = request_payload['lat']
  lng = request_payload['lng']
  opts = request_payload['opts']
  puts opts.pretty_inspect

  if lat.nil? || lng.nil?
    status 400
    return { error: 'Invalid request payload' }.to_json
  end

  geocoding_instance = settings.geocoding_instance
  result = geocoding_instance.gen_route(lat, lng, opts)
  { result: result }.to_json
end
