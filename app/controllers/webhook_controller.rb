require 'line/bot'
require 'net/https'
require 'uri'
require 'date'

class WebhookController < ApplicationController
  protect_from_forgery with: :null_session # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
  
  
  def fortune
    url = "http://api.jugemkey.jp/api/horoscope/free/"
    today = Date.today.strftime('%Y/%m/%d')
    
    fortune_url = "#{url}#{today}"

    uri = URI.parse(fortune_url)
    http = Net::HTTP.new(uri.host, uri.port)
    
    req = Net::HTTP::Get.new(uri.request_uri)
    
    res = http.request(req)
    api_response = JSON.parse(res.body)
    
    ranking = {}
    api_response["horoscope"]["#{today}"].each do |index|
      ranking[index["rank"].to_s.to_sym] = index["sign"]
    end
    
    return ranking
    
  end
  

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head 470
    end

    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          choice = ["牡羊座", "牡牛座", "双子座", "蟹座", "獅子座", "乙女座", "天秤座", "蠍座", "射手座", "山羊座", "水瓶座", "魚座"]
          if event.message['text'].include?("ランキング") then
            cookie = fortune
            result = "今日のランキングだよ！︎"
            (1..12).each do |n|
              result << "\n#{n}位\t#{cookie[n.to_s.to_sym]}"
            end
          elsif choice.include?(event.message['text']) then
            result = "星座だね"
          else    
            result = "ランキングのことしか分からないよ"
          end
          message = {
            type: 'text',
            text: result
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    }
    head :ok
  end
end
