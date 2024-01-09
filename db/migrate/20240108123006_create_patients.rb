class CreatePatients < ActiveRecord::Migration[7.1]
  def change
    create_table :patients do |t|
      t.string :name
      t.string :first_name
      t.string :last_name
      t.integer :age
      t.string :gender
      t.string :height

      t.timestamps
    end
  end
end
