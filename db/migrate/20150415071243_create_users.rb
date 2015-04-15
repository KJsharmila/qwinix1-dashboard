class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
    	 t.string   :name
    	 t.string   :username
         t.string   :email
         t.string   :status
         t.string   :user_type
         t.string   :password
         t.string   :password_confirmation
      t.timestamps
    end
  end
end
