

class ForkDelta
  API_END_POINT = "https://api.forkdelta.com/returnTicker"

  def self.get_tokens_price
    response = HTTParty.get("#{API_END_POINT}")
    parsed_response = response.parsed_response
    return parsed_response
  end

  def self.find_tokens(**args)
    market           = args[:market]
    own_tokens       = args[:own_tokens]
    forkdelta_market = market
    formated_own_tokens = []
    forkdelta_market.each do |fd_token|
      own_tokens.each do |token|
        token_address = token["tokenInfo"]["address"]
        if fd_token.last["tokenAddr"] == token_address
          token_balance = Ethplorer.get_balance(token)
          token_name    = token["tokenInfo"]["name"]
          token_symbol  = token["tokenInfo"]["symbol"]
          formated_own_tokens.push({
            token_name: token_name,
            token_symbol: token_symbol,
            token_address: token_address,
            token_balance: token_balance,
            token_bid: ( '%.10f' % fd_token.last['last'] ).sub(/0+$/,'').to_f
          })
        end
      end
    end
    return formated_own_tokens
  end

  def self.get_price(bot, message)
    address = Subscriber.get_address(message)
    market = ForkDelta.get_tokens_price
    response_string = ForkDelta.formated_tokens_price({
      market: market,
      address: address,
      updated_at: Time.now.getlocal("-03:00").strftime("%d/%m/%Y %H:%M")
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
      forkdelta_tokens = ForkDelta.find_tokens({
        market: market,
        own_tokens: tokens[:data]
      })
      if forkdelta_tokens
        forkdelta_tokens.each do |token|
          chilean = token[:token_bid] * token[:token_balance] * current_eth.to_i
          clp_total += chilean if chilean > 2500
          response_string += "• #{token[:token_symbol]}: #{token[:token_bid]}\n#{Helper.number_to_currency(chilean.round)}\n\n" if chilean > 2500
        end
      end
      puts "TOTAL: #{Helper.number_to_currency(clp_total.round)}"
      response_string += "----------------------------------\nTotal: #{Helper.number_to_currency(clp_total.round)}"
    end
    return response_string
  end
end
