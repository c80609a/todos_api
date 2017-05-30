require 'rails_helper'

RSpec.describe AuthorizeApiRequest do

  # создаём тестового пользователя
  let(:user) {create(:user)}

  # подделываем 'Authorization' заголовок
  # noinspection RubyStringKeysInHashInspection
  let(:header) {{'Authorization' => token_generator(user.id)}}

  # Invalid request subject
  subject(:invalid_request_obj) {described_class.new({})}

  # Valid request subject
  subject(:request_obj) {described_class.new(header)}

  # Тест для AuthorizeApiRequest#call
  # это единственная точка входа в этот service class
  describe '#call' do

    # вернёт user object, если запрос валидный
    context 'when valid request:' do
      it 'returns user object' do
        result = request_obj.call
        expect(result[:user]).to eq(user)
      end
    end

    # вернёт сообщение об ошибке, если запрос невалидный
    context 'when invalid request:' do

      context 'with missing token:' do
        it 'raises a MissingToken error' do
          expect do
            invalid_request_obj.call
          end.to raise_error(ExceptionHandler::MissingToken, 'Missing token')
        end
      end

      context 'when invalid token:' do
        subject(:invalid_request_obj) do
          described_class.new('Authorization' => token_generator(5))
        end

        it 'raises an InvalidToken error' do
          expect do
            invalid_request_obj.call
          end.to raise_error(ExceptionHandler::InvalidToken, /Invalid token/)

        end

      end

      context 'when token is expired:' do
        # noinspection RubyStringKeysInHashInspection
        let(:header) {{'Authorization' => expired_token_generator(user.id)}}
        subject(:request_obj) {described_class.new(header)}

        it 'raises ExpiresSignature error' do
          expect do
            request_obj.call
          end.to raise_error(ExceptionHandler::InvalidToken, /Signature has expired/)
        end

      end#context

    end#context

  end#describe#call

end#describe