class Item < ApplicationRecord
  belongs_to :todo, optional: true
  validates_presence_of :name
end
