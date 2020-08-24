class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.string :confirm_token
      t.boolean :confirm_email
      t.string :access_token
      t.string :uid

      t.timestamps
    end
  end
end
