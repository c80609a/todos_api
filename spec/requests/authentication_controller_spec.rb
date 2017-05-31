require 'rails_helper'

RSpec.describe AuthenticationController, type: :request do

  describe 'POST /auth/login' do

    # <editor-fold desc="# создаём тестовые данные">
    # создаём тестового пользователя
    let!(:user) { create(:user) }
    # устанавливаем заголовки для авторизации
    let(:headers) { valid_headers.except('Authorization') }
    # задаём правильные и неправильные credentials
    let(:valid_credentials) do
      {
          email: user.email,
          password: user.password
      }.to_json
    end
    let(:invalid_credentials) do
      {
          email: Faker::Internet.email,
          password: Faker::Internet.password
      }.to_json
    end

    # set request.headers to our custom headers
    # before { allow(request).to receive(:headers).and_return(headers) }
    # </editor-fold>

    context 'Когда запрос валидный:' do
      before { post '/auth/login', params: valid_credentials, headers: headers }

      it 'вернётся authentication token' do
        expect(json['auth_token']).not_to be_nil
      end

    end

    context 'Когда запрос невалидный:' do
      before { post '/auth/login', params: invalid_credentials, headers: headers }

      it 'вернётся failure message' do
        expect(json['message']).to match(/Invalid credentials/)
      end

    end

  end

end
