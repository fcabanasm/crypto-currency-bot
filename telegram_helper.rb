class TelegramHelper
  def self.get_info(bot, message)
    response_string = "Tus datos de Telegram son:\n"
    response_string += "Nombre: #{message.chat.first_name} #{message.chat.last_name}\n"
    response_string += "ID: #{message.chat.id}\n"
    response_string += "Username: @#{message.chat.username}\n"
    bot.api.send_message(chat_id: message.chat.id, text: "#{response_string}")
  end
end
