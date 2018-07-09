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
    today = Date.today
    
    fortune_url = 'http://api.jugemkey.jp/api/horoscope/free/#{today.year}/#{today.month}/#{today.day}'

    uri = URI.parse(fortune_url)
    http = Net::HTTP.new(uri.host, uri.port)
    
    req = Net::HTTP::Get.new(uri.request_uri)
    
    res = http.request(req)
    puts res.code, res.msg
    # api_response = JSON.parse(res.body)
    # api_response['droplets'].each do |item|
    #   puts item['sign'], item['rank']
    
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
          fortune
          if event.message['text'] == "乙女座は何位？" then
            message = {
              type: 'text',
              text: "1位だよ！いい日になるよ！"
            }
          else
            message = {
              type: 'text',
              text: "どうだろう？たぶん悪くはないよ"
            }
          end
          client.reply_message(event['replyToken'], message)
        end
      end
    }
    head :ok
  end
end
