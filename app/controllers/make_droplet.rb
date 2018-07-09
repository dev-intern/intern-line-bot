require 'net/https'
require 'uri'
require 'json'
require 'date'

today = Date.today

droplet_ep = 'http://api.jugemkey.jp/api/horoscope/#{today.year}/#{today.month}/#{today.day}'
token = '(トークン)'

uri = URI.parse(droplet_ep)
http = Net::HTTP.new(uri.host, uri.port)

http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

req = Net::HTTP::Get.new(uri.request_uri)
req["Authorization"] = "bearer #{token}"

res = http.request(req)
puts res.code, res.msg
api_response = JSON.parse(res.body)
api_response['droplets'].each do |item|
  puts item['sign'], item['rank']

end