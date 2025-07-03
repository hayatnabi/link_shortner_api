class AddSecurityToLinks < ActiveRecord::Migration[8.0]
  def change
    add_column :links, :password_digest, :string
    add_column :links, :expires_at, :datetime
  end
end
