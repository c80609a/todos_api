require 'rails_helper'

RSpec.describe AuthenticateUser do
  # create test user
  let(:user) { create(:user) }
  # valid request subject
  subject(:valid_auth_obj) { described_class.new(user.email, user.password) }
  # invalid request subject
  subject(:invalid_auth_obj) { described_class.new('foo', 'bar') }

  # test suite for AuthenticateUser#call
  describe '#call' do

    # returns token when valid request
    context 'when valid credentials' do
      it 'returns an auth token' do
        token = valid_auth_obj.call
        expect(token).not_to be_nil
      end
    end#context

    # raises Authentication Error when invalid request
    context 'when invalid credentials' do
      it 'raises authentication error' do
        expect do
          invalid_auth_obj.call
        end.to raise_error(ExceptionHandler::AuthenticationError, /Invalid credentials/)
      end
    end#context

  end#describe

end