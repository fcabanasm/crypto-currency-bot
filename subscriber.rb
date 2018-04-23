require 'csv'

class Subscriber
  def self.get_address(message)
    chat_id = message.chat.id
    csv_file_path = 'subscribeds.csv'
    if message.text.split(" ")[1]
      return message.text.split(" ")[1]
    else
      CSV.foreach(csv_file_path, {headers: true, header_converters: :symbol}) do |row|
        if row[:chat_id] == chat_id.to_s
          return row[:address]
        end
      end
    end
  end
end
