module ExceptionHandler
  extend ActiveSupport::Concern

  # определим кастомные error subclasses - rescue catches `StandardErrors`
  class AuthenticationError < StandardError; end
  class MissingToken < StandardError; end
  class InvalidToken < StandardError; end
  class ExpiredSignature < StandardError; end

  included do

    # define custom handlers
    rescue_from ActiveRecord::RecordInvalid, with: :four_twenty_two
    rescue_from ExceptionHandler::AuthenticationError, with: :unauthorized_request
    rescue_from ExceptionHandler::MissingToken, with: :four_twenty_two
    rescue_from ExceptionHandler::InvalidToken, with: :four_twenty_two
    rescue_from ExceptionHandler::ExpiredSignature, with: :unauthorized_request

    rescue_from ActiveRecord::RecordNotFound do |e|
      json_response({message: e.message}, :not_found)
    end

  end

  private
  
  # JSON ответ со статус-кодом 422 - unprocessable_entity
  def four_twenty_two(e)
    json_response({message: e.message}, :unprocessable_entity)
  end

  # JSON ответ со статус-кодом 401 - unauthorized
  def unauthorized_request(e)
    json_response({message: e.message}, :unauthorized)
  end

end