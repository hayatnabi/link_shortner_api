class CreateLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :links do |t|
      t.string :original_url
      t.string :short_code
      t.integer :click_count

      t.timestamps
    end
  end
end
