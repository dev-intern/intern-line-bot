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
  
  
  def fortune(rank_frag, period)
    url = "http://api.jugemkey.jp/api/horoscope/free/"
    date = Date.period.strftime('%Y/%m/%d')
    
    fortune_url = "#{url}#{date}"

    uri = URI.parse(fortune_url)
    http = Net::HTTP.new(uri.host, uri.port)
    
    req = Net::HTTP::Get.new(uri.request_uri)
    
    res = http.request(req)
    api_response = JSON.parse(res.body)
    
    if rank_frag == 1 then
      ranking = {}
      api_response["horoscope"]["#{date}"].each do |index|
        ranking[index["rank"].to_s.to_sym] = index["sign"]
      end
    else
      ranking = {}
      api_response["horoscope"]["#{date}"].each do |index|
        ranking[index["sign"].to_sym] = {}
        ranking[index["sign"].to_sym][:"rank"] = index["rank"]
        ranking[index["sign"].to_sym][:"content"] = index["content"]
        ranking[index["sign"].to_sym][:"item"] = index["item"]
      end
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
          if event.message['text'].include?("昨日") then
            date = yesterday
          elsif event.message['text'].include?("明日") then
            date = tommorow
          else
            date = today
          end
          if event.message['text'].include?("ランキング") then
            period = Date.date.strftime("%m月%d日")
            cookie = fortune(1, date)
            result = "#{period}のランキングだよ！︎"
            (1..12).each do |n|
              result << "\n#{n}位\t#{cookie[n.to_s.to_sym]}"
            end
          elsif event.message['text'].in?(choice) then
            constellation = event.message['text']
            cookie = fortune(0, date)
            all_contents = cookie[:"#{constellation}"]
            result = "#{constellation}の運勢\n順位:\t#{all_contents[:"rank"]}\n#{all_contents[:"content"]}\nラッキーアイテム:\t#{all_contents[:"item"]}"
          else
            result = "\"ランキング\"か星座(漢字)を教えてね"
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
