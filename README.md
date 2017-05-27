# Subj

Учебный проект (Todo list) для укрепления навыков REST, RSpec, Rails API only applications

Оригинал (by https://github.com/akabiru):

https://scotch.io/tutorials/build-a-restful-json-api-with-rails-5-part-one
https://scotch.io/tutorials/build-a-restful-json-api-with-rails-5-part-two

# Intro

Согласно [Rails 5 release notes](http://guides.rubyonrails.org/5_0_release_notes.html), генерация API only приложения:

* подразумевает запуск приложения с неполным промежуточным слоем (limited set of middleware)
* создаст `ApplicationController`, унаследовав его от `ActionController::API`, а не от `ActionController::Base`
* не будет генерить view файлы

# Prerequisites

```
$ ruby -v # ruby 2.3.1
$ rails -v # Rails 5.0.1
```

# API Endpoints

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

# Project Setup

```
$ rails new todos-api --api -T
```

Добавляем gems в `Gemfile`:

```

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

```
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

```
741f1e0: [2017-05-26 05:41:49 +0300] настроил библиотеки в rails_helper.rb
50eea5d: [2017-05-26 05:35:20 +0300] $ rails g rspec:install
0590726: [2017-05-26 05:07:36 +0300] подключил библиотеки rspec_rails, factory_girl_rails, faker, shoulda_matchers, database_cleaner
08767e1: [2017-05-26 05:02:31 +0300] .gitignore
630ffe2: [2017-05-26 05:01:35 +0300] $ rails new todos_api --api -T
```

# Models

Генерим модели:

```
$ rails g model Todo title:string created_by:string
$ rails g model Item name:string done:boolean todo:references
$ rails db:migrate
```

Пишем падающие тесты:

* `spec/models/todo_spec.rb`
* `spec/models/item_spec.rb`

Правим модели, фиксим ошибки, прогоняем тесты ещё раз. Git log:

```
111efd0: [2017-05-26 06:56:14 +0300] $ echo ruby-2.3.3 > .ruby-version
951ec82: [2017-05-26 06:52:22 +0300] Реализовал код моделей Item и Todo, которые проходят тесты
ef55bc9: [2017-05-26 06:51:43 +0300] подключил и настроил Guard и Zeus
5a222d1: [2017-05-26 06:51:15 +0300] написал падающие тесты для Item и Todo
796a5af: [2017-05-26 06:14:41 +0300] добавил модели Todo и Item
```

# Controllers

Добавляем контроллеры:

```
$ rails g controller Todos
$ rails g controller Items
```

Пишем тесты, но: мы не будем писать тесты для контроллеров. 
Мы будем писать тесты для [запросов (requests specs)](https://www.relishapp.com/rspec/rspec-rails/docs/request-specs/request-spec).

> According to RSpec, the official recommendation of the Rails team and the RSpec core team is to write request specs instead.

```
$ mkdir spec/requests && touch spec/requests/{todos_spec.rb,items_spec.rb}
$ touch spec/factories/{todos.rb,items.rb}
```

Лабаем фабрики (factories):

* `spec/factories/todos.rb`:

```
FactoryGirl.define do
  factory :todo do
    title { Faker::Lorem.word }
    created_by { Faker::Number.number(10) }
  end
end
```

* `spec/factories/items.rb`:

```
FactoryGirl.define do
  factory :item do
    name { Faker::StarWars.character }
    done false
    todo_id nil
  end
end
```

Затем пишем тесты для API: `spec/requests/todos_spec.rb`. Замечаем, что код использует некий метод `json` - это support.

Добавляем `spec/support`:

```
$ mkdir spec/support && touch spec/support/request_spec_helper.rb
```

С содержимым:

```
module RequestSpecHelper
  # Parse JSON response to ruby hash
  def json
    JSON.parse(response.body)
  end
end
```

Чтобы этот файл require, включаем его в `rails_helper.rb`:

```
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

```
35f80b1: [2017-05-26 08:58:06 +0300] добавил spec/support/request_spec_helper.rb с модулем внутри и методом json
2327375: [2017-05-26 08:41:13 +0300] поправил Guardfile для тестирования запросов
a194537: [2017-05-26 08:40:07 +0300] добавил падающие тесты в spec/requests для Todos и Items
be49be8: [2017-05-26 08:38:49 +0300] добавил spec/factories для Items и Todos
f3b516d: [2017-05-26 07:44:13 +0300] поправил ошибку в rails_helper.rb
ae68a3c: [2017-05-26 06:57:03 +0300] $ rails g controller Todos
8e90b88: [2017-05-26 06:56:35 +0300] $ rails g controller Items
```

Определяем маршруты в `routes.rb`:

```
Rails.application.routes.draw do
  resources :todos do
    resources :items
  end
end
```

Здесь мы создали todo resource со вложенным item resource.
This enforces the 1:m (один ко многим) на уровне маршрутизации.

Запускаем тесты еще раз, наблюдаем, что ошибки маршрутизации исчезли, остались ошибки контроллера. Создаём методы контроллера `app/controllers/todos_controller.rb`.

Git log:

```
a7912c9: [2017-05-26 21:24:56 +0300] реализовал методы todos_controller.rb
860ed6d: [2017-05-26 21:24:36 +0300] поправил опечатку в Guardfile
79c4271: [2017-05-26 09:00:08 +0300] routes.rb: enforce the 1:m association на уровне маршрутизации
```

Анализируем хелперы, которые он использует:

* `json_responce` - этот хелпер отдаёт JSON и HTTP код. Определяем его в `app/controllers/concerns/response.rb`:

```
module Response
  def json_response(object, status = :ok)
    render json: object, status: status
  end
end
```

* `set_todo` - это приватный метод контроллера (callback method), который ищет todo by id.
 Если запись не будет найдена в базе, ActiveRecord will throw an exception `ActiveRecord::RecordNotFound`. 
 Мы защитимся от этой ошибки, вернув HTTP код `404`. 
 Для этого создадим модуль `app/controllers/concerns/exception_handler.rb`. Особо отметим пару вещей:
   * в первую очередь, расширим его функцонал `extend ActiveSupport::Concern`, что даёт более graceful `included` метод
   * для защиты от exceptions используем метод `rescue_from`
   * подмечаем, что в `todos_controller.rb` используем `create!` вместо `create`, что может 
   вызвать `ActiveRecord::RecordInvalid`. А при наличии `exception_handler.rb` не надо лабать 
   вложенные `if..else` в контроллере. 
 
 Добавим concern-модули в `application_controller.rb`:
 
```
class ApplicationController < ActionController::API
  include Response
  include ExceptionHandler
end
```
 
Запустим тесты - все зелёные. 
 
Git log:

```
8f47908: [2017-05-27 19:54:28 +0300] добавляю concerns-модули: ExceptionHandler и Responce, внедряю их в ApplicationController. Тесты проходят.
6d29dea: [2017-05-27 19:53:11 +0300] todos_spec.rb: исправляю опечатки и ошибки.
```

Запустим сервер for some good old manual testing - `$ rails s` - и совершим пару запросов:

```
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