class JsonWebToken

  # определим секрет для кодирования/декодирования токена
  HMAC_SECRET = Rails.application.secrets.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    # установим крайний срок
    payload[:exp] = exp.to_i
    # подпишем token секретом
    JWT.encode(payload, HMAC_SECRET)
  end

  def self.decode(token)
    body = JWT.decode(token, HMAC_SECRET)[0]
    HashWithIndifferentAccess.new body
      # защитимся от возможных исключительных ситуаций
  rescue JWT::ExpiredSignature, JWT::VerificationError => e
    # вызовем кастомное исключение, которая будет обработана кастомным обработчиком
    raise ExceptionHandler::ExpiredSignature, e.message
  end

end