require './ethplorer'
require './etherdelta'
require './cryptomkt'
require './ethereum'
require './surbtc'
require './forkdelta'
require './helper'
require './subscriber'
require './cryptocompare'
require './telegram_helper'

require 'telegram/bot'
require 'dotenv/load'
require 'pry'

require 'csv'

api_token = ENV["BOT_API_TOKEN"]

Telegram::Bot::Client.run(api_token) do |bot|
  bot.listen do |message|
    if message.text
      message_text = message.text.split(" ")
      puts "USER: #{ message.chat.username} (#{message.chat.first_name} #{message.chat.last_name})"
      case message.text
      when '/id'
        TelegramHelper.get_info(bot, message)
      when '/start'
        bot.api.send_message(chat_id: message.chat.id, text: "El Bot se encuentra en desarrollo, contactar a @fcabanasm para más información")
      when '/help'
        bot.api.send_message(chat_id: message.chat.id, text: "Contactar a @fcabanasm para suscripción")
      else
        if message && message.text
          message_text = message.text.split(" ")
          puts "TEXT: #{message_text}"
          puts "FECHA: #{Time.now.getlocal("-03:00").strftime("%d/%m/%Y %H:%M")}"
          case message_text[0].downcase
          when '/clp', '/all'
            EtherDelta.get_price(bot, message)
          when '/clp2'
            Cryptocompare.get_tokens_price(bot, message)
          when '/clp3'
            ForkDelta.get_price(bot, message)
          when '/info', '/tokens'
            Ethplorer.all_tokens(bot, message)
          when '/ed'
            EtherDelta.get_market(bot, message)
          when '/eth'
            Ethereum.get_eth_info(bot, message)
          when '/btc'
            Surbtc.get_btc_info(bot, message)
          when '/bch'
            Surbtc.get_bch_info(bot, message)
          else
            begin
              bot.api.send_message(chat_id: message.chat.id, text: "El Bot se encuentra en desarrollo, contactar a @fcabanasm para más información")
            rescue => e
              puts "Telegram error: #{e}"
            end
          end
        end
      end
    end
  end
end
