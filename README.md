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