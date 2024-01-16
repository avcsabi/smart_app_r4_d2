class CreatePatients < ActiveRecord::Migration[7.1]
  def change
    create_table :patients do |t|
      t.string :name
      t.string :first_name
      t.string :last_name
      t.date :birth_date
      t.string :gender
      t.string :phone_number
      t.string :communication_language

      t.timestamps
    end
  end
end
