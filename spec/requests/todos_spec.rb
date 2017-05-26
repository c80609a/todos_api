require 'rails_helper'

RSpec.describe 'Todos API', type: :request do
  
  # инициализируем тестовые данные
  let!(:todos) { create_list(:todo, 10) }
  let(:todo_id) { todos.first.id }

  # лабаем test suit для GET /todos
  describe 'GET /todos' do
    
    # совершаем HTTP get запрос перед каждым примером
    before { get '/todos' }

    it 'вернёт списки всех дел' do
      # NOTE:: `json` это custom helper, который помогает парсить JSON ответы
      
      expect(json).not_to be_empty
      expect(json.size).to eq(10)

    end

    it 'вернёт статус 200' do
      expect(response).to have_http_status(200)
    end

  end


  # лабаем test suit для GET /todos/:id
  describe 'GET /todos/:id' do
    
    before { get '/todos/#{todo_id}' }

    context 'Если запись существует:' do
      
      it 'вернёт указанный список дел' do
        expect(json).to_not be_empty
	expect(json['id']).to eq todo_id
      end

      it 'вернёт статус 200' do
        expect(response).to have_http_status(200)
      end

    end

    context 'Если запись не существует:' do
      
      # переопределим значение :todo_id - присвоим заведомо несуществующее
      let(:todo_id) { 10500 }

      it 'вернёт статус 404' do
        expect(response).to have_http_status(404)
      end

      it 'вернёт сообщение о том, что запись не найдена' do
        expect(response.body).to match(/Couldn't find Todo/)
      end

    end#context

  end#describe

  # test suit для POST /todos 
  describe 'POST /todos' do
    
    let(:valid_attributes) do
     { 
        title: 'Learn Elm',
        created_by: '1'
     }
    end

    context 'Если запрос валидный: ' do
      before { post '/todos', params: valid_attributes }

      it 'должен создасться список дел' do
        expect(json['title']).to eq 'Learn Elm'
      end

      it 'вернёт статус 201' do
        expect(response).to have_http_status(201)
      end

    end#context

    context 'Если запрос невалидный:' do
      before { post '/todos', params: {title:'asdf'} }

      it 'вернёт статус 422' do
        expect(response).to have_http_status(422)
      end

      it 'вернёт сообщение о невалидном запросe' do
        expect(response.body).to match(/Validation failed: 'created_by' can't be blank/)
      end

    end#context

  end#describe

  describe 'POST /todo/:id' do
    
    let(:valid_attributes) do
      { title: 'Shopping' }
    end

    context 'Если запись существует:' do
      before { put '/todos/#{todo_id}', params: valid_attributes }
      
      it 'атрибуты существующей записи обновятся' do
        expect(response.body).not_to be_empty
      end

      it 'вернёт статус 204' do
        expect(response).to have_http_status(204)
      end

    end#context

  end#describe

  describe 'DELETE /todo/:id' do
    before { delete '/todo/#{todo_id}' }

    it 'вернёт статус 204' do
      expect(response).to have_http_status(204)
    end

  end#describe

end
