class CreateCasSessions < ActiveRecord::Migration
  def self.up
    create_table :cas_sessions do |t|
      t.string   :service_ticket 
      t.string   :session_id
    end
	
	add_index :cas_sessions, [:service_ticket]
  end
 
  def self.down
    drop_table :cas_sessions
	remove_index  :cas_sessions, [:service_ticket]
  end
end

