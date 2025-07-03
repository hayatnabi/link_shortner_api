class AddLocationToClicks < ActiveRecord::Migration[8.0]
  def change
    add_column :clicks, :city, :string
    add_column :clicks, :country, :string
    add_column :clicks, :region, :string
    add_column :clicks, :lat, :float
    add_column :clicks, :lon, :float
  end
end
