require './etherdelta'
require './cryptomkt'
require 'httparty'
require 'dotenv/load'

class Ethplorer
  def self.get_tokens(address)
    begin
      response      = HTTParty.get("#{ENV["API_URL"]}/getAddressInfo/#{address}?apiKey=#{ENV["API_KEY"]}")
      json_response = response.parsed_response
      tokens = json_response["tokens"]
      if tokens
        return {data: tokens, valid: true}
      else
        return {data: nil, valid: false}
      end
    rescue Net::ReadTimeout => error
      return {data: error, valid: false}
    end
  end

  def self.get_eth(address)
    begin
      response      = HTTParty.get("#{ENV["API_URL"]}/getAddressInfo/#{address}?apiKey=#{ENV["API_KEY"]}")
      json_response = response.parsed_response
      if json_response && json_response["ETH"] && json_response["ETH"]["balance"]
        eth = json_response["ETH"]["balance"]
        return {data: eth, valid: true}
      else
        return {data: nil, valid: false}
      end
    rescue Net::ReadTimeout => err
      return {data: err, valid: false}
    end

  end

  def self.token_info_string(tokens)
    if tokens && tokens.length > 0
      tokens_string = ''
      tokens.each do |token|
        name = token["tokenInfo"]["name"]
        symbol = token["tokenInfo"]["symbol"]
        balance = Ethplorer.get_balance(token)
        tokens_string += "• #{symbol}: #{balance}\n"
      end
    else
      tokens_string = ""
    end
    return tokens_string
  end

  def self.get_balance(token)
    decimals = token["tokenInfo"]["decimals"]
    balance = token["balance"]
    balance_i = balance.to_i
    if decimals
      while balance_i.to_s.length < decimals.to_i
        balance_i = balance_i.to_s.insert(-(balance_i.to_s.length+1), "0")
      end
      formated_balance = balance_i.to_s.insert(-(decimals.to_i+1), '.')
    else
      formated_balance = balance_i
    end
    balance = formated_balance.to_f
    return balance
  end

  def self.all_tokens(bot, message)
    address = Subscriber.get_address(message)
    if address
      tokens = Ethplorer.get_tokens(address)
      eth_ethplorer = Ethplorer.get_eth(address)
      if tokens[:valid] && eth_ethplorer[:valid]
        tokens_string = "• ETH: #{eth_ethplorer[:data]}\n"
        tokens_string += Ethplorer.token_info_string(tokens[:data])
        bot.api.send_message(parse_mode: 'HTML', chat_id: message.chat.id, text: "#{tokens_string}")
      else
        bot.api.send_message(parse_mode: 'HTML', chat_id: message.chat.id, text: "Ha ocurrido un error con ethplorer.")
      end
    else
      bot.api.send_message(parse_mode: 'HTML', chat_id: message.chat.id, text: "La dirección no es válida")
    end

  end

end
