require 'httparty'

class Cryptomkt
  def self.get_eth_price
    response = Cryptomkt.get_eth_market
    if response && response.code == 200
      @data = response.parsed_response["data"][0]
      @last_price = @data["bid"].to_i
      #  "timestamp"=>"2017-11-05T13:32:57.895292",
      #  "bid"=>"194400",
      #  "last_price"=>"194400",
      #  "high"=>"201700",
      #  "low"=>"194210",
      #  "ask"=>"198490",
      #  "market"=>"ETHCLP"
    else
      @last_price = nil
    end
    return @last_price
  end

  def self.formated_response(response)
    @formated_response = ""
    @data = response.parsed_response["data"][0] if response.code == 200
    if @data
      @last_price = @data["last_price"].to_i
      @compra = @data["ask"].to_i
      @venta = @data["bid"].to_i
      @volumen = @data["volume"].to_f
      @mayor = @data["high"].to_f
      @menor = @data["low"].to_f

      @formated_response += "Última orden: #{Helper.number_to_currency(@last_price)}\n"
      @formated_response += "Compra: #{Helper.number_to_currency(@compra)}\n"
      @formated_response += "Venta: #{Helper.number_to_currency(@venta)}\n"
      @formated_response += "Volúmen: #{@volumen}"
    end
    return @formated_response
  end

  def self.get_eth_market
    response = HTTParty.get("https://api.cryptomkt.com/v1/ticker?market=ETHCLP")
    return response
  end
end
