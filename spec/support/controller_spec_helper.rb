module ControllerSpecHelper

  # генерируем token из user id
  def token_generator(user_id)
    JsonWebToken.encode(user_id: user_id)
  end

  # генерируем просроченный token
  def expired_token_generator(user_id)
    JsonWebToken.encode({user_id: user_id}, (Time.now.to_i - 10))
  end

  # вернёт валидные headers
  # noinspection RubyStringKeysInHashInspection
  def valid_headers
    {
        'Authorization' => token_generator(user.id),
        'Content-Type' => 'application/json'
    }
  end

  # вернёт неправильные заголовки
  # noinspection RubyStringKeysInHashInspection
  def invalid_headers
    {
        'Authorization' => nil,
        'Content-Type' => 'application/json'
    }
  end

end