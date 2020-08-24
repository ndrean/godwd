class ChangeTypeArrayItinaries < ActiveRecord::Migration[6.0]
  def change
    remove_column :itinaries, :start_gps, array: true
    remove_column :itinaries, :end_gps, array: true
    add_column :itinaries, :end_gps, :decimal, array: true, default: []
    add_column :itinaries, :start_gps, :decimal, array: true, default: []
  end
end
