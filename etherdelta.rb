require 'socket.io-client-simple'
require './ethereum'
require './ethplorer'
require './subscriber'
require './helper'

class EtherDelta

  def self.find_token(**args)
    market            = args[:market]
    token_symbol      = args[:token_symbol]
    token_address     = args[:token_address]
    etherdelta_market = market["returnTicker"]

    found_token = etherdelta_market["ETH_#{token_symbol}"]
    if found_token && found_token != "" && found_token["tokenAddr"] == token_address
      return found_token
    else
      etherdelta_market.each do |token|
        if token.last["tokenAddr"] == token_address
          return token.last
        end
      end
    end
    return nil
  end

  def self.get_market_from_file
    return {
      data: YAML.load_file('etherdelta_market.yml'),
      updated_at: File.ctime('etherdelta_market.yml').getlocal("-03:00").strftime("%d/%m/%Y %H:%M"),
      minutes_from_now: (Time.now.getlocal("-03:00") - File.ctime('etherdelta_market.yml').getlocal("-03:00")) / 60.to_i
    }
  end

  def self.update_market_file
    params = {
      message: "",
      updated: false,
      file: EtherDelta.get_market_from_file
    }
    if params[:file][:minutes_from_now] >= 5
      socket = EtherDelta.get_socket
      unless socket[:valid]
        params[:message] = "Ups...ha ocurrido un error con ED #{socket[:data].class.name}: #{socket[:data].message}"
        return params
      end
      socket[:data].on :connect do
        socket[:data].emit('getMarket', {})
        socket[:data].on :market do |response|
          if response["returnTicker"] != nil && response["returnTicker"] != '' && response["returnTicker"] != {}
            File.write('etherdelta_market.yml', response.to_yaml)
            params[:file] = EtherDelta.get_market_from_file
            params[:updated] = true
          end
        end
      end
      socket[:data].on :error do |err|
        params[:message] = "Ups...ha ocurrido un error con ED: #{err}"
      end
    end
    return params
  end

  def self.formated_market(**args)
    token_symbol = args[:token]
    market = args[:market]
    filtered_market = market["returnTicker"]["ETH_#{token_symbol}"] if token_symbol
    updated_at = args[:updated_at]
    if filtered_market != nil && filtered_market != ''
      address = filtered_market['tokenAddr']
      change = filtered_market['percentChange']
      last = '%.10f' % filtered_market['last']
      bid = '%.10f' % filtered_market['bid']
      ask = '%.10f' % filtered_market['ask']
      current_eth = Ethereum.price
      chilean = last.to_f * current_eth
      response_string = "#{updated_at}\n-------------------------\n"
      response_string += "Nombre: #{token_symbol}\n"
      response_string += "Dirección: #{address}\n"
      response_string += "Variación: #{change}\n"
      response_string += "Última orden: #{last}\n"
      response_string += "Venta: #{bid}\n"
      response_string += "Compra: #{ask}\n"
      response_string += "CLP: #{Helper.number_to_currency(chilean.round)}\n"
    else
      response_string = "Ups...no se ha encontrado el token: #{token_symbol}"
    end
    return response_string
  end

  def self.get_market(bot, message)
    message_text = message.text.split(" ")
    token_symbol = message_text[1].upcase if message_text[1]

    updated_market_file = EtherDelta.update_market_file
    file = updated_market_file[:file]

    market = file[:data]
    response_string = EtherDelta.formated_market({
      market: market,
      token: token_symbol,
      updated_at: file[:updated_at]
    })
    bot.api.send_message(parse_mode: 'HTML', chat_id: message.chat.id, text: "#{response_string}")
  end

  def self.formated_tokens_price(**args)
    address = args[:address]
    market = args[:market]
    updated_at = args[:updated_at]
    tokens = Ethplorer.get_tokens(address)
    eth_ethplorer = Ethplorer.get_eth(address)
    current_eth = Ethereum.price
    response_string = "#{updated_at}\n----------------------------------\n"
    eth_value = eth_ethplorer[:valid] ? (eth_ethplorer[:data] * current_eth) : 0
    clp_total = eth_value
    if tokens[:valid] && tokens[:data] && tokens[:data].length > 0
      response_string += "• ETH: #{Helper.number_to_currency(current_eth)}\n#{Helper.number_to_currency(eth_value.round)}\n\n"
      tokens[:data].each do |token|
        token_name = token["tokenInfo"]["name"]
        token_symbol = token["tokenInfo"]["symbol"]
        token_address = token["tokenInfo"]["address"]
        etherdelta_token = EtherDelta.find_token({
          market: market,
          token_symbol: token_symbol,
          token_address: token_address
        })
        if etherdelta_token
          balance = Ethplorer.get_balance(token)
          bid = '%.10f' % etherdelta_token['bid']
          chilean = bid.to_f * current_eth.to_i * balance
          clp_total += chilean if chilean > 2500
          response_string += "• #{token_symbol}: #{bid.sub(/0+$/,'')}\n#{Helper.number_to_currency(chilean.round)}\n\n" if chilean > 2500
        end
      end
      puts "TOTAL: #{Helper.number_to_currency(clp_total.round)}"
      response_string += "----------------------------------\nTotal: #{Helper.number_to_currency(clp_total.round)}"
    end
    return response_string
  end

  def self.get_price(bot, message)
    address = Subscriber.get_address(message)
    updated_market_file = EtherDelta.update_market_file
    file = updated_market_file[:file]
    market = file[:data]
    response_string = EtherDelta.formated_tokens_price({
      market: market,
      address: address,
      updated_at: file[:updated_at]
    })
    bot.api.send_message(parse_mode: 'HTML', chat_id: message.chat.id, text: "#{response_string}")
  end

  def self.get_socket
    begin
      socket = SocketIO::Client::Simple.connect 'wss://socket.etherdelta.com/socket.io', :transport => "websocket"
      socket.auto_reconnection = false
      return {data: socket, valid: true}
      rescue => e
        return {data: e, valid: false}
      end

  end
end
