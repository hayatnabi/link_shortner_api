class Link < ApplicationRecord
  has_many :clicks, dependent: :destroy
end
