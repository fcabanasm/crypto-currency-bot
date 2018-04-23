require './cryptomkt'
require './surbtc'
require './helper'

class Ethereum
  def self.price
    current_eth = Cryptomkt.get_eth_price
    unless current_eth
      current_eth = Surbtc.get_eth_price
      unless current_eth
        current_eth = 700000
      end
    end
    return current_eth
  end

  def self.get_eth_info(bot, message)
    address = Subscriber.get_address(message)
    cryptomkt_eth = Cryptomkt.formated_response(Cryptomkt.get_eth_market)
    surbtc_eth = Surbtc.formated_response(Surbtc.get_eth_market)
    @formated_response = "Cryptomkt:\n#{cryptomkt_eth}\n-----------------------------\nSurbtc:\n#{surbtc_eth}"
    bot.api.send_message(chat_id: message.chat.id, text: "#{@formated_response}")
  end

end
