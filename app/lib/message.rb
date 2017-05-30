class Message

  def self.not_found(record = 'record')
    "Запись #{record} не найдена."
  end

  def self.invalid_credentials
    'Invalid credentials'
  end

  def self.invalid_token
    'Invalid token'
  end

  def self.missing_token
    'Missing token'
  end

  def self.unauthorized
    'Unauthorized request'
  end

  def self.account_created
    'Аккаунт успешно создан'
  end

  def self.account_not_created
    'Аккаунт не был создан'
  end

  def self.expired_token
    'Sorry, your token has expired. Please login to continue.'
  end

end