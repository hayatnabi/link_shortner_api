class Link < ApplicationRecord
  has_many :clicks, dependent: :destroy
  has_secure_password validations: false
end
