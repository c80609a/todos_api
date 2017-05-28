require 'rails_helper'

RSpec.describe 'Items API' do

  # тестовые данные
  let!(:todo) { create(:todo) }
  # noinspection RubyResolve
  let!(:items) { create_list(:item, 20, todo_id: todo_id) }
  let(:todo_id) { todo.id }
  let(:id) { items.first.id }

  describe 'GET /todos/:todo_id/items' do
    before { get "/todos/#{todo_id}/items" }

    context 'Если todo существует:' do

      it 'должен вернуть код 200' do
        expect(response).to have_http_status(200)
      end

      it 'должен вернуть список дел указанного todo' do
        puts json
        expect(json.size).to eq(20)
      end

    end

    context 'Если todo не существует:' do
      let(:todo_id) { 10500 }

      it 'должен вернуть код 404' do
        expect(response).to have_http_status(404)
      end

      it 'должен вернуть not found сообщение' do
        expect(response.body).to match(/Couldn't find Todo/)
      end

    end#context

  end#describe

  describe 'GET /todos/:todo_id/items/:id' do
    before { get "/todos/#{todo_id}/items/#{id}" }

    context 'если дело (item) существует:' do
      it 'должен вернуть код 200' do
        expect(response).to have_http_status(200)
      end
      it 'должен вернуть его данные' do
        expect(json['id']).to eq id
      end
    end

    context 'если дело (item) не существует:' do
      let(:id) { 10500 }

      it 'должен вернуть код 404' do
        expect(response).to have_http_status(404)
      end
      it 'должен вернуть ответ record not found' do
        expect(response.body).to match(/Couldn't find Item/)
      end
    end

  end#describe

  describe 'POST /todos/:todo_id/items' do
    let(:valid_attributes) do
      { name: 'Visit Narina',
        done: false
      }
    end

    context 'если параметры валидные:' do

      before do
        post "/todos/#{todo_id}/items", params: valid_attributes
      end

      it 'должен вернуть код 201' do
        expect(response).to have_http_status(201)
      end

    end

    context 'если параметры невалидные:' do

      before do
        post "/todos/#{todo_id}/items", params: {}
      end

      it 'должен вернуть код 422' do
        expect(response).to have_http_status(422)
      end

      it 'ответ должен содержать сообщение об ошибке' do
        expect(response.body).to match(/Validation failed/)
      end
    end
  end#describe

  describe 'PUT /todos/:todo_id/items/:id' do

    let(:valid_attributes) do
      { name: 'Mozart' }
    end

    before do
      put "/todos/#{todo_id}/items/#{id}"
    end

    context 'если дело (item) существует:' do

      it 'должен вернуть код 204' do
        expect(response).to have_http_status(204)
      end

      it 'должен обновить item' do
        item = Item.find(id)
        expect(item.name).to eq valid_attributes[:name]
      end

    end

    context 'если дело (item) несуществует:' do
      let(:id) { 10500 }

      it 'должен вернуть код 404' do
        expect(response).to have_http_status(404)
      end

      it 'ответ должен содержать сообщение об ошибке' do
        expect(response.body).to match(/Couldn't find Item/)
      end

    end

  end#describe

  describe 'DELETE /todos/:todo_id/items/:id' do

    before do
      delete "/todos/#{todo_id}/items/#{id}"
    end

    context 'если запись существует:' do

      it 'должен вернуть код 200' do
        expect(response).to have_http_status(200)
      end

      it 'запись должна быть удалена' do
        item = Item.find_by_id(id)
        expect(item).to eq nil
      end

    end

    context 'если запись не существует:' do
      let(:id) { 10500 }

      it 'должен вернуть код 404' do
        expect(response).to have_http_status(404)
      end

      it 'должно вернуться сообщение об ошибке' do
        expect(response.body).to match(//)
      end

    end

  end#describe

end