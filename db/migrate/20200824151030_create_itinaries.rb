class CreateItinaries < ActiveRecord::Migration[6.0]
  def change
    create_table :itinaries do |t|
      t.date :date
      t.string :start
      t.string :end
      t.string :start_gps, array: true, default:[]
      t.string :end_gps, array: true, default:[]
      t.decimal :distance

      t.timestamps
    end
  end
end
