require 'rails_helper'

RSpec.describe User, type: :model do

  # Association test
  # Убеждаемся, что User habtm Todos
  it { should have_many(:todos) }

  # Validation tests
  # Убеждаемся, что запись обладает нужными свойствами перед тем
  # как запишем их в базу
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:password_digest) }

end
