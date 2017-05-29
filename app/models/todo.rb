class Todo < ApplicationRecord
  has_many :items, :dependent => :destroy
  belongs_to :user
  validates_presence_of :title, :created_by
end
