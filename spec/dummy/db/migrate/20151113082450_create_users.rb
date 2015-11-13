class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.timestamps
    end

    User.create_cached_methods_table!
  end
end
