require 'httparty'
require './helper'

class Surbtc

  def self.get_eth_market
    response = HTTParty.get("https://www.surbtc.com/api/v2/markets/eth-clp/ticker.json")
    return response
  end

  def self.get_eth_price
    response = Surbtc.get_eth_market
    if response && response.code == 200
      @data = response.parsed_response["ticker"]
      @last_price = @data["max_bid"][0].to_i == 0 ? nil : @data["max_bid"][0].to_i
     # "last_price"=>["202201.0", "CLP"],
     # "min_ask"=>["206990.0", "CLP"],
     # "max_bid"=>["202201.0", "CLP"],
     # "volume"=>["95.194497718", "ETH"],
     # "price_variation_24h"=>"0.047",
     # "price_variation_7d"=>"0.032"

    else
      @last_price = nil
    end
    return @last_price
  end

  def self.get_btc_info(bot, message)
    response = HTTParty.get("https://www.surbtc.com/api/v2/markets/btc-clp/ticker.json")
    if response && response.parsed_response
      @formated_response = Surbtc.formated_response(response)
      # "last_price"=>["4001000.0", "CLP"],
      #  "min_ask"=>["4349994.0", "CLP"],
      #  "max_bid"=>["4001000.0", "CLP"],
      #  "volume"=>["43.29147314", "BTC"],
      #  "price_variation_24h"=>"-0.101",
      #  "price_variation_7d"=>"-0.198"
      bot.api.send_message(chat_id: message.chat.id, text: "#{@formated_response}")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Ups, ha ocurrido un error, al consultar la API de SurBTC")
    end
    return @last_price
  end

  def self.get_bch_info(bot, message)
    response = HTTParty.get("https://www.surbtc.com/api/v2/markets/bch-clp/ticker.json")
    if response && response.parsed_response
      @formated_response = Surbtc.formated_response(response)
      # "last_price"=>["4001000.0", "CLP"],
      #  "min_ask"=>["4349994.0", "CLP"],
      #  "max_bid"=>["4001000.0", "CLP"],
      #  "volume"=>["43.29147314", "BTC"],
      #  "price_variation_24h"=>"-0.101",
      #  "price_variation_7d"=>"-0.198"
      bot.api.send_message(chat_id: message.chat.id, text: "#{@formated_response}")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Ups, ha ocurrido un error, al consultar la API de SurBTC")
    end
    return @last_price
  end

  def self.formated_response(response)
    @formated_response = ""
    @data = response.parsed_response["ticker"] if response.code == 200
    if @data
      @last_price = @data["last_price"][0].to_i
      @compra = @data["min_ask"][0].to_i
      @venta = @data["max_bid"][0].to_i
      @volumen = @data["volume"][0].to_f
      @price_variation_24h = @data["price_variation_24h"].to_f
      @price_variation_7d = @data["price_variation_7d"].to_f

      @formated_response += "Última orden: #{Helper.number_to_currency(@last_price)}\n"
      @formated_response += "Compra: #{Helper.number_to_currency(@compra)}\n"
      @formated_response += "Venta: #{Helper.number_to_currency(@venta)}\n"
      @formated_response += "Volúmen: #{@volumen}\n"
      @formated_response += "Variación 24h: #{@price_variation_24h}\n"
      @formated_response += "Variación 7d: #{@price_variation_7d}"
    end
    return @formated_response
  end
end
