class AuthorizeApiRequest

  def initialize(headers = {})
    @headers = headers
  end

  # Service entry point - вернёт валидный user object
  def call
    {
        user: user
    }
  end

  private

  attr_reader :headers

  def user
    # проверяем наличие пользователя в базе данных
    # memoize user object
    @user ||= User.find(decoded_auth_token[:user_id]) if decoded_auth_token
  # handle "user not found"
  rescue ActiveRecord::RecordNotFound => e
    # raise custom error
    raise(
        ExceptionHandler::InvalidToken,
        ("#{Message.invalid_token} #{e.message}")
    )
  end

  # decode auth token
  def decoded_auth_token
    @decoded_auth_token ||= JsonWebToken.decode(http_auth_header)
  end

  # check for token in `Authorization` header
  def http_auth_header
    if headers['Authorization'].present?
      return headers['Authorization'].split(' ').last
    end
    raise(ExceptionHandler::MissingToken, Message.missing_token)
  end

end