# Subj

Учебный проект (Todo list) для укрепления навыков REST, RSpec, Rails API only applications

Оригинал (by https://github.com/akabiru):

* https://scotch.io/tutorials/build-a-restful-json-api-with-rails-5-part-one
* https://scotch.io/tutorials/build-a-restful-json-api-with-rails-5-part-two

# Содержание

<ul>
 <li><a href='#part-1'>1. Part 1</a>
   <ul>
       <li>1.1. <a href='#intro'>Intro</a></li>
       <li>1.2. <a href='#prerequisites'>Prerequisites</a></li>
       <li>1.3. <a href='#api-endpoints'>API Endpoints</a></li>
       <li>1.4. <a href='#project-setup'>Project Setup</a></li>
       <li>1.5. <a href='#configuration'>Configuration</a></li>
       <li>1.6. <a href='#models'>Models</a></li>
       <li>1.7. <a href='#controllers'>Controllers</a>
         <ul>
             <li>1.7.1 <a href='#generate'>Generate</a></li>
             <li>1.7.2 <a href='#fabrics'>Fabrics</a></li>
             <li>1.7.3 <a href='#todo-api'>Todo API</a></li>
             <li>1.7.4 <a href='#todo-items-api'>Todo items API</a></li>
         </ul>
       </li>
   </ul>
 </li> 
</ul>

# Part 1

Первая часть охватывает моменты:

* генерация Rails API приложения
* Настройка RSpec и сопутствующих фреймворков: 
    * FactoryGirl, 
    * Database Cleaner, 
    * Shoulda Matchers, 
    * Faker
* создание моделей и контроллеров путём TDD
* ручная проверка с помощью ~~httpie~~ `curl`

## Intro

Согласно [Rails 5 release notes](http://guides.rubyonrails.org/5_0_release_notes.html), генерация API only приложения:

* подразумевает запуск приложения с неполным промежуточным слоем (limited set of middleware)
* создаст `ApplicationController`, унаследовав его от `ActionController::API`, а не от `ActionController::Base`
* не будет генерить view файлы

## Prerequisites

```bash
$ ruby -v # ruby 2.3.1
$ rails -v # Rails 5.0.1
```

## API Endpoints

API приложения, в конечном итоге, будет исповедовать REST архитектуру:

| Endpoint	                | Functionality                |
| :---------------------:   | :---------------------------:|
| `POST /signup`            |  Signup                      |
| `POST /auth/login`	    |  Login                       |
| `GET /auth/logout`        |  Logout                      |
| `GET /todos`	            |  List all todos              |
| `POST /todos`	            |  Create a new todo           |
| `GET /todos/:id`	        |  Get a todo                  |
| `PUT /todos/:id`	        |  Update a todo               |
| `DELETE /todos/:id`	    |  Delete a todo and its items |
| `GET /todos/:id/items`	|  Get a todo item             |
| `PUT /todos/:id/items`	|  Update a todo item          |
| `DELETE /todos/:id/items` |	 Delete a todo item        |

## Project Setup

```bash
$ rails new todos-api --api -T
```

Добавляем gems в `Gemfile`:

```ruby
group :development, :test do
  gem 'rspec-rails', '~> 3.5'
end

group :test do
  gem 'factory_girl_rails', '~> 4.0'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'faker'
  gem 'database_cleaner'
end

```

Далее:

```bash
$ bundle install
$ rails g rspec:install
$ mkdir spec/factories
```

## Configuration

```ruby
# require database cleaner at the top level
require 'database_cleaner'

# [...]
# configure shoulda matchers to use rspec as the test framework and full matcher libraries for rails
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# [...]
RSpec.configuration do |config|
  # [...]
  # add `FactoryGirl` methods
  config.include FactoryGirl::Syntax::Methods

  # start by truncating all the tables but then use the faster transaction strategy the rest of the time.
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  # start the transaction strategy as examples are run
  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
  # [...]
end
```

Git log:

```bash
741f1e0: [2017-05-26 05:41:49 +0300] настроил библиотеки в rails_helper.rb
50eea5d: [2017-05-26 05:35:20 +0300] $ rails g rspec:install
0590726: [2017-05-26 05:07:36 +0300] подключил библиотеки rspec_rails, factory_girl_rails, faker, shoulda_matchers, database_cleaner
08767e1: [2017-05-26 05:02:31 +0300] .gitignore
630ffe2: [2017-05-26 05:01:35 +0300] $ rails new todos_api --api -T
```

## Models

Генерим модели:

```bash
$ rails g model Todo title:string created_by:string
$ rails g model Item name:string done:boolean todo:references
$ rails db:migrate
```

Пишем падающие тесты:

* `spec/models/todo_spec.rb`
* `spec/models/item_spec.rb`

Правим модели, фиксим ошибки, прогоняем тесты ещё раз. Git log:

```bash
111efd0: [2017-05-26 06:56:14 +0300] $ echo ruby-2.3.3 > .ruby-version
951ec82: [2017-05-26 06:52:22 +0300] Реализовал код моделей Item и Todo, которые проходят тесты
ef55bc9: [2017-05-26 06:51:43 +0300] подключил и настроил Guard и Zeus
5a222d1: [2017-05-26 06:51:15 +0300] написал падающие тесты для Item и Todo
796a5af: [2017-05-26 06:14:41 +0300] добавил модели Todo и Item
```

## Controllers

### Generate

Добавляем контроллеры:

```bash
$ rails g controller Todos
$ rails g controller Items
```

Пишем тесты, но: мы не будем писать тесты для контроллеров.
 
Мы будем писать тесты для [запросов (requests specs)](https://www.relishapp.com/rspec/rspec-rails/docs/request-specs/request-spec).

> According to RSpec, the official recommendation of the Rails team and the RSpec core team is to write request specs instead.

```bash
$ mkdir spec/requests && touch spec/requests/{todos_spec.rb,items_spec.rb}
```

### Fabrics

Лабаем фабрики (factories):

* `$ touch spec/factories/{todos.rb,items.rb}`

* `spec/factories/todos.rb`:

```ruby
FactoryGirl.define do
  factory :todo do
    title { Faker::Lorem.word }
    created_by { Faker::Number.number(10) }
  end
end
```

* `spec/factories/items.rb`:

```ruby
FactoryGirl.define do
  factory :item do
    name { Faker::StarWars.character }
    done false
    todo_id nil
  end
end
```

### Todo API

Затем пишем тесты для API: `spec/requests/todos_spec.rb`. 

Замечаем, что код использует некий метод `json` - это support.

Добавляем `spec/support`:

```bash
$ mkdir spec/support && touch spec/support/request_spec_helper.rb
```

С содержимым:

```ruby
module RequestSpecHelper
  # Parse JSON response to ruby hash
  def json
    JSON.parse(response.body)
  end
end
```

Чтобы этот файл require, включаем его в `rails_helper.rb`:

```ruby
# [...]
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
# [...]
RSpec.configuration do |config|
  # [...]
  config.include RequestSpecHelper, type: :request
  # [...]
end
```

Запускаем тесты, они падают. Git log:

```bash
35f80b1: [2017-05-26 08:58:06 +0300] добавил spec/support/request_spec_helper.rb с модулем внутри и методом json
2327375: [2017-05-26 08:41:13 +0300] поправил Guardfile для тестирования запросов
a194537: [2017-05-26 08:40:07 +0300] добавил падающие тесты в spec/requests для Todos и Items
be49be8: [2017-05-26 08:38:49 +0300] добавил spec/factories для Items и Todos
f3b516d: [2017-05-26 07:44:13 +0300] поправил ошибку в rails_helper.rb
ae68a3c: [2017-05-26 06:57:03 +0300] $ rails g controller Todos
8e90b88: [2017-05-26 06:56:35 +0300] $ rails g controller Items
```

Определяем маршруты в `routes.rb`:

```ruby
Rails.application.routes.draw do
  resources :todos do
    resources :items
  end
end
```

Здесь мы создали todo resource со вложенным item resource.

This enforces the 1:m (один ко многим) на уровне маршрутизации.

Запускаем тесты еще раз, наблюдаем, что ошибки маршрутизации исчезли, остались ошибки контроллера.
 
Создаём методы контроллера `app/controllers/todos_controller.rb`.

Git log:

```bash
a7912c9: [2017-05-26 21:24:56 +0300] реализовал методы todos_controller.rb
860ed6d: [2017-05-26 21:24:36 +0300] поправил опечатку в Guardfile
79c4271: [2017-05-26 09:00:08 +0300] routes.rb: enforce the 1:m association на уровне маршрутизации
```

Анализируем хелперы, которые он использует:

* `json_responce` - этот хелпер отдаёт JSON и HTTP код. Определяем его в `app/controllers/concerns/response.rb`:

```ruby
module Response
  def json_response(object, status = :ok)
    render json: object, status: status
  end
end
```

* `set_todo` - это приватный метод контроллера (callback method), который ищет todo by id. Если запись не будет найдена в базе, ActiveRecord will throw an exception `ActiveRecord::RecordNotFound`. Мы защитимся от этой ошибки, вернув HTTP код `404`. Для этого создадим модуль `app/controllers/concerns/exception_handler.rb`. Особо отметим пару вещей:
   * в первую очередь, расширим его функцонал `extend ActiveSupport::Concern`, что даёт более graceful `included` метод
   * для защиты от exceptions используем метод `rescue_from`
   * подмечаем, что в `todos_controller.rb` используем `create!` вместо `create`, что может 
   вызвать `ActiveRecord::RecordInvalid`. А при наличии `exception_handler.rb` не надо лабать 
   вложенные `if..else` в контроллере. 
 
Добавим concern-модули в `application_controller.rb`:
 
```ruby
class ApplicationController < ActionController::API
  include Response
  include ExceptionHandler
end
```
 
Запустим тесты - все зелёные. 
 
Git log:

```bash
8f47908: [2017-05-27 19:54:28 +0300] добавляю concerns-модули: ExceptionHandler и Responce, внедряю их в ApplicationController. Тесты проходят.
6d29dea: [2017-05-27 19:53:11 +0300] todos_spec.rb: исправляю опечатки и ошибки.
```

Запустим сервер for some good old manual testing - `$ rails s` - и совершим пару запросов:

```bash
$ curl -X POST localhost:3000/todos
# пусто

$ curl -X POST localhost:3000/todos -d 'title=Mozart&created_by=1'
# {"id":1,"title":"Mozart","created_by":"1","created_at":"2017-05-27T18:36:08.705Z","updated_at":"2017-05-27T18:36:08.705Z"}

$ curl -X PUT localhost:3000/todos/1 -d 'title=Bethoven'
# пусто
# а в логе сервера: Completed 204 No Content - и запись обновилась

$ curl -X DELETE localhost:3000/todos/1
# пусто
# Completed 204 No Content - и запись удалена


```

### Todo items API

Лабаем падающие тесты в `spec/requests/items_spec.rb`.
 
Затем пишем код в контроллере `items_controller.rb`. 

Несколько замечаний про код в контроллере:

* используются callbacks, внутри которых определяются переменные `@todo` и `@item`
* причем, когда определяем `@item`:
    * запись ищется среди дел `@todo` с помощью метода `find_by!`, который raise `ActiveRecord::RecordNotFound`, если запись не будет найдена (если бы использовали метод `find_by`, то он вернул бы `nil` в этом случае) 
    * также используется условие `if @todo`
    * т.е. callback `set_todo_item` может либо вернуть `nil` (если нет данного списка дел), либо raise `ActiveRecord::RecordNotFound` (если нет среди дел данного списка искомого item-a)
* используем метод `head` - который возвращает ответ без контента, только заголовки

Прогоняем тесты ещё раз - все проходят.

Запускаем сервер `rails s` и в отдельном терминале проверяем API вручную:

```bash
curl -X POST localhost:3000/todos -d 'title=Mozart&created_by=1'
# {"id":1,"title":"Mozart","created_by":"1","created_at":"2017-05-28T11:25:18.295Z","updated_at":"2017-05-28T11:25:18.295Z"}

curl -X POST localhost:3000/todos/1/items -d 'name=Listen 5th symphony&done=false'
# [{"id":1,"name":"Listen 5th symphony","done":false,"todo_id":1,"created_at":"2017-05-28T11:27:49.946Z","updated_at":"2017-05-28T11:27:49.946Z"}]

curl localhost:3000/todos/1/items
# [{"id":1,"name":"Listen 5th symphony","done":false,"todo_id":1,"created_at":"2017-05-28T11:27:49.946Z","updated_at":"2017-05-28T11:27:49.946Z"}] 

curl -X PATCH localhost:3000/todos/1/items/1 -d 'name=Work'
# ничего

curl localhost:3000/todos/1/items
# [{"id":1,"name":"Work","done":false,"todo_id":1,"created_at":"2017-05-28T11:27:49.946Z","updated_at":"2017-05-28T11:28:36.807Z"}]

curl -X PATCH localhost:3000/todos/1/items/1 -d 'done=true'
# ничего 

curl localhost:3000/todos/1/items
# [{"id":1,"name":"Work","done":true,"todo_id":1,"created_at":"2017-05-28T11:27:49.946Z","updated_at":"2017-05-28T11:29:36.222Z"}]

curl -X DELETE localhost:3000/todos/2/items/1
# ничего

curl localhost:3000/todos/2/items
# []
```

Git log:

```bash
04ccb68: [2017-05-28 15:27:13 +0300] Заставляю дружить item.rb c Fabric Girl в контексте теста: 'если запись не существует:'.
89b7b29: [2017-05-28 15:25:48 +0300] исправляю опечатки в items_spec.rb
4f05894: [2017-05-28 15:25:31 +0300] Реализую код контроллера items_controller.rb - тесты зелёные.
30b44e6: [2017-05-28 11:33:27 +0300] Написал тесты запросов в `items_spec.rb`.
40c247a: [2017-05-28 06:41:27 +0300] rails_helper.rb: чистим лог перед каждым запуском какого-нибудь теста.
8f47908: [2017-05-27 19:54:28 +0300] добавляю concerns-модули: ExceptionHandler и Responce, внедряю их в ApplicationController.
```

# Part 2

Вторая часть охватывает следующие темы:

* 

## Authentication

В нашем приложении API подразумевает пользователей с доступом к только к своим ресурсам 
(managing their own resources). 

### Model User

Создадим модель:

```bash
rails g model User name email password_digest
rails db:migrate
rails db:test:prepare
```

Обращаем внимание на `password_digest` (почему используем это поле вместо обычного `password`?) и двигаем далее -
причина будет объяснена позднее.

### Spec for User

Лабаем `spec/models/user_spec.rb`:
 
```ruby
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
```

### Fabric for User

Создаем фабрику `spec/factories/user.rb`:

```ruby
FactoryGirl.define do
  factory :user do
    name { Faker::Name.name }
    email 'foo@bar.com'
    password 'foobar'
  end
end
```

Прогоняем новые тесты - все упали. 

### Model User implementing

Имплементируем код модели.
 
```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :todos, :dependent => :destroy, :foreign_key => :created_by
  validates_presence_of :name, :email, :password_digest
end
```

Обращаем внимание на пару моментов:

* `has_secure_password` ([api.rubyonrails.org](http://api.rubyonrails.org/classes/ActiveModel/SecurePassword/ClassMethods.html)):
> Встраивает парольную защиту, основанную на BCrypt.
> Добавляет валидации в модель: 
> 1) пароль должен присутствовать при создании записи; 
> 2) длина пароля не должна превышать 72 символа;
> 3) добавляется подтверждение пароля с помощью атрибута `password_confirmation`

### Gem `bcrypt` comes on

Чтобы он заработал, добавляем в Gemfile библиотеку `bcrypt`:

```ruby
gem 'bcrypt', '~> 3.1.7'
```

* `:foreign_key => :created_by` ([api.rubyonrails.org](http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#method-i-belongs_to-label-Options), [www.w3schools.com](https://www.w3schools.com/sql/sql_foreignkey.asp)):
> FOREIGN KEY - это ключ, используемый для связи двух таблиц.
> Это поле (или несколько полей) одной таблицы, которые ссылаются на PRIMARY KEY поле другой таблицы.
> Таблица, содержащая FOREIGN KEY, называется дочерней таблицей, а таблица, на которую ссылаются
> её поля - родительской таблицей.
> С помощью опции `:foreign_key` можно определить имя поля, которое будет использоваться в ассоциации, как FOREIGN KEY.

Делаем `bundle` и запускаем тесты ещё раз - всё зелёное.

Git log:

```
bc926c2: [2017-05-29 20:57:11 +0300] Добавил модель User, добавил тесты для неё, связал с моделью Todo, подключил gem 'bcrypt', добавил фабрику.
```

Можно создавать пользователей с защищёнными паролями. 

## Next steps

Теперь мы прикрутим (wire up) оставшиеся части authentication system:

* JsonWebToken - Encode and decode jwt tokens
* AuthorizeApiRequest - Authorize each API request
* AuthenticateUser - Authenticate users
* AuthenticationController - Orchestrate authentication process

## JSON web token

Для начала ответим на вопрос - что это такое - [token based authentication](https://stackoverflow.com/questions/1592534/what-is-token-based-authentication):

> Всё очень просто. 
> Позволяем пользователю ввести логин/пароль
> и в ответ даём ему *time-limited token*, который открывает
> ему временный доступ к закрытым ресурсам по этому token-у и уже без 
> использования логина/пароля.

Добавляем в Gemfile `gem 'jwt'` и делаем `bundle`.

Наш класс будет жить в `lib` директории. Но, надо помнить одну вещь:

> As of Rails 5, [autoloading is disabled in production](http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#autoloading-is-disabled-after-booting-in-the-production-environment) because of thread safety.

Для нас это вопрос, требущий решения, т.к. `lib` - это часть auto load paths.

```bash
$ mkdir app/lib
$ touch app/lib/json_web_token.rb
```

И определим в новом файле jwt singleton:

```ruby
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
```

Этот singleton оборачивает (wraps) `JWT`, предоставляя методы по кодированию/декодированию token-ов.
`encode` метод создаёт tokens на основе `payload` (user id) и на основе expiration period.
Каждое Rails приложение имеет свой уникальный secret, и мы используем его для подписи этого token-а.

`decode` метод работает в обратную сторону, используя Rails application's secret. Если
декодирование провалится (либо по причиние истечения срока, либо token невалидный), `JWT` вызовет
соответствующее исключение, которое обработаем модулем `ExceptionHandler`, код которого
выглядит так (с учётом того, что там уже был код, и он изменился):

```ruby
module ExceptionHandler
  extend ActiveSupport::Concern

  # Define custom error subclasses - rescue catches `StandardErrors`
  class AuthenticationError < StandardError; end
  class MissingToken < StandardError; end
  class InvalidToken < StandardError; end

  included do
    # Define custom handlers
    rescue_from ActiveRecord::RecordInvalid, with: :four_twenty_two
    rescue_from ExceptionHandler::AuthenticationError, with: :unauthorized_request
    rescue_from ExceptionHandler::MissingToken, with: :four_twenty_two
    rescue_from ExceptionHandler::InvalidToken, with: :four_twenty_two

    rescue_from ActiveRecord::RecordNotFound do |e|
      json_response({ message: e.message }, :not_found)
    end
  end

  private

  # JSON response with message; Status code 422 - unprocessable entity
  def four_twenty_two(e)
    json_response({ message: e.message }, :unprocessable_entity)
  end

  # JSON response with message; Status code 401 - Unauthorized
  def unauthorized_request(e)
    json_response({ message: e.message }, :unauthorized)
  end
end
```

В этом модуле мы определяем кастомные `StandardError` подклассы, которые помогут перехватывать 
исключения. Определив эти кастомные подклассы, мы теперь можем написать `rescue_from` them once raised.

Git log:

```
96c867c: [2017-05-30 06:58:58 +0300] Добавил код в модуль ExceptionHanlder, который спасает от исклю- чительных ситуаций с помощью внутренних подкл
0224dc2: [2017-05-30 06:26:43 +0300] Подключил `gem 'jwt'`.
d557a18: [2017-05-30 06:26:23 +0300] Добавил класс `lib/json_web_token.rb`.
```

## Authorize Api Request

Напишем класс, который будет в ответе за авторизацию всех API запросов, и который будет 
проверять, что все поступающие запросы имеют правильный token и id пользователя 
(This class will be responsible for authorizing all API requests making sure that all 
requests have a valid token and user payload).

Т.к. это auth service class, то он будет жить в `app/auth`:

```bash
# создаём файл для класса
$ mkdir app/auth
$ touch app/auth/authorize_api_request.rb

# создаем файл с тестами
$ mkdir spec/auth
$ touch spec/auth/authorize_api_request_spec.rb
```

## Spec for AuthorizeApiRequest

Начнём с определения спецификации `spec/auth/authorize_api_request_spec.rb`:

```ruby
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
```

`AuthorizeApiRequest` service должен быть оснащён единственным методом
`call` который вернёт объект класса User, если всё в порядке, или
будет вызвано исключение в обратном случае.

Обращаем внимание на то, что spec использует пару вспомогательных методов:

* `token_generator` - генерирует test token
* `expired_token_generator` - генерирует expired token

Имплементируем их в `spec/support`:

```bash
$ touch spec/support/controller_spec_helper.rb
```

```ruby
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
```

Обращаем внимание на то, что заведены еще два вспомогательных метода: 
`valid_headers` и `invalid_headers`. Чтобы методами этого модуля можно
было воспользоваться, его нужно include в `rails_helper.rb`.

Пока мы в `rails_helper.rb`, заодно уберём `type: :request` при включении
`RequestSpecHelper` - т.е. сделаем так, чтобы этот модуль был доступен
всем типам тестов:

```ruby
RSpec.configure do |config|
  # [...]
  # previously `config.include RequestSpecHelper, type: :request`
  config.include RequestSpecHelper
  config.include ControllerSpecHelper
  # [...]
end
```

Запускаем все тесты - падают только 4 новых.

Git log:

```
ea569e4: [2017-05-30 11:59:35 +0300] Добавил опцию `:optional => true` в ассоциацию `belongs_to` класса Todo.
3d13284: [2017-05-30 11:58:51 +0300] 1) Добавил тесты `authorize_api_request_spec.rb`; 2) Добавил `controller_spec_helper.rb`; 3) включил `controll
```

## AuthorizeApiRequest model implementing

Теперь займёмся кодом модели `app/auth/authorize_api_request.rb`:

```ruby
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
```

Сервис `AuthorizeApiRequest` извлекает token из заголовков авторизации,
пытается декодировать его и вернуть правильный user объект. 

Помимо этого присутствует еще один singleton класс `Message`, 
в котором живут все сообщения. Определим его в директории `app/lib`,
т.к. он не domain-specific.

Прогоняем все тесты `zeus test spec -fd`: passed.

Git log:

```
b32d6bf: [2017-05-30 14:01:17 +0300] Добавил недостающий ExceptionHandler::ExpiredSignature класс.
061a746: [2017-05-30 14:00:27 +0300] Добавил класс Message.
63aa1ed: [2017-05-30 14:00:08 +0300] Имплементировал `authorize_api_request.rb`.
```

## Authenticate User

Этот класс будет отвечать за авторизацию пользователей с помощью пары email/password.

```bash
$ touch app/auth/authenticate_user.rb
$ touch spec/auth/authenticate_user_spec.rb
```

Начнём со спецификации:

```ruby
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
        token = invalid_auth_obj.call
        expect(token).to raise_error(ExceptionHandler::AuthenticationError, /Invalid credentials/)
      end
    end#context
    
  end#describe
  
end
```

Сервис `AuthenticateUser` также имеет единственную entry point в виде метода `#call`. 
Метод должен вернуть token, если email/password от пользователя пришли правильные.
В противном случае - вызовется ошибка авторизации.

Прогоняем тесты, они упали. Займёмся имплементацией кода `app/auth/authenticate_user.rb`:

```ruby
class AuthenticateUser
  
  def initialize(email, password)
    @email = email
    @password = password
  end
  
  def call
    JsonWebToken.encode(user_id: user.id) if user
  end
  
  private
  
  attr_reader :email, :password
  
  # verify user credentials
  def user
    user = User.find_by(email: email)
    return user if user && user.authenticate(password)
    # raise Authentication Error if credentials are invalid
    raise(ExceptionHandler::AuthenticationError, Message.invalid_credentials)
  end
  
end
```

Сервис `AuthenticateUser` принимает email/password и выдаёт token, если всё в порядке.

Запускаем тесты - все проходят.

Git log:

```
5b07548: [2017-05-30 18:08:53 +0300] Добавил сервис `authenticate_user.rb`.
609c2da: [2017-05-30 18:08:18 +0300] Добавил тесты `authenticate_user_spec.rb`.
```

## Authentication Controller

Этот контроллер будет управлять сервисом авторизации, который мы только-что создали.

```bash
$ rails g controller Authentication
```

Начнём с тестов `spec/requests/authentication_controller_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe AuthenticationController, type: :controller do
  
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
```

Контроллер доступен по маршруту `/auth/login`: принимает на вход user credentials
и отвечает JSON-ом.

```
class AuthenticationController < ApplicationController

  def authenticate
    auth_token = AuthenticateUser.new(auth_params[:email], auth_params[:password]).call
    json_response(auth_token: auth_token)
  end

  private

  def auth_params
    params.permit(:email, :password)
  end

end
```

Добавим маршрут в `config/routes.rb`:

```
# config/routes.rb
Rails.application.routes.draw do
  # [...]
  post 'auth/login', to: 'authentication#authenticate'
end
```

Запускаем тесты - все прошли.

Git log:

```
1829faa: [2017-05-31 11:30:56 +0300] Добавил контроллер `authentication_controller.rb` + маршрут.
cd733e7: [2017-05-31 11:24:49 +0300] Добавил тесты `spec/requests/authentication_controller_spec.rb`.
```

## User Controller

