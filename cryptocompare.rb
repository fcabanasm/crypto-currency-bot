require 'httparty'

class Cryptocompare
  URL = "https://min-api.cryptocompare.com/data/pricemulti"
  CURRENCIES = "USD,CLP,ETH,BTC"

  def self.get_eth_price
    response = HTTParty.get("https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=CLP")
    if response && response.code == 200
      @data = response.parsed_response
      @last_price = @data["CLP"].to_i
    else
      @last_price = nil
    end
    return @last_price
  end

  def self.get_tokens_price(bot, message)
    address = Subscriber.get_address(message)
    if address
      tokens = Ethplorer.get_tokens(address)
      eth_ethplorer = Ethplorer.get_eth(address)
      if eth_ethplorer[:valid]
        array_symbols = ["ETH"]
      else
        array_symbols = []
      end
      if tokens[:valid] && eth_ethplorer[:valid]
        tokens[:data].map{|x|
          if x["tokenInfo"]["symbol"].gsub(/[^[:ascii:]]/, "") != ''
            array_symbols.push( x["tokenInfo"]["symbol"].gsub(/[^[:ascii:]]/, "") )
          end
        }
        string_symbols = array_symbols.join(",")
        response = HTTParty.get("#{URL}?fsyms=#{string_symbols}&tsyms=#{CURRENCIES}")
        parsed_response = response.parsed_response
        current_eth = Ethereum.price

        total = 0
        response_string = "#{Time.now.getlocal("-03:00").strftime("%d/%m/%Y %H:%M")}\n----------------------------------\n"
        initial = false
        tokens[:data].each do |token|
          token_name = token["tokenInfo"]["name"]
          token_symbol = token["tokenInfo"]["symbol"]
          parsed_response.each do |key, value|
            if !initial && key == "ETH"
              balance = eth_ethplorer[:data]
              clp = current_eth * balance
              total += clp
              response_string += "• #{key}: #{Helper.number_to_currency(current_eth)}\n#{Helper.number_to_currency(clp.round)}\n\n" if clp.round > 0
              initial = true
            end
            if token_symbol != "ICOS" && token_symbol == key
              balance = Ethplorer.get_balance(token)
              clp = value["ETH"] * balance * current_eth
              total += clp if clp > 5000
              response_string += "• #{key}: #{('%.10f'%value["ETH"]).sub(/0+$/,'')}\n#{Helper.number_to_currency(clp.round)}\n\n" if clp > 5000
            end
          end
        end
        puts "Total: #{Helper.number_to_currency(total.round)}"
        response_string += "------------------------------------\nTotal: #{Helper.number_to_currency(total.round)}"
        bot.api.send_message(parse_mode: 'HTML', chat_id: message.chat.id, text: response_string)
      else
        bot.api.send_message(parse_mode: 'HTML', chat_id: message.chat.id, text: "Ha ocurrido un error con ethplorer.")
      end
    else
      bot.api.send_message(parse_mode: 'HTML', chat_id: message.chat.id, text: "La dirección no es válida")
    end
  end
end
