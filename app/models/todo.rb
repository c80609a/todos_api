class Todo < ApplicationRecord
  has_many :items, :dependent => :destroy
  belongs_to :user, :optional => true
  validates_presence_of :title, :created_by
end
