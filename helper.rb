class Helper
  def self.number_to_currency(num)
    "$#{num.to_s.gsub(/\d(?=(...)+$)/, '\0.')}"
  end
end
