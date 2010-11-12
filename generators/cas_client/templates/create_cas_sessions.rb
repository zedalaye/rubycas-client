class CreateCasSessions < ActiveRecord::Migration
  def self.up
    create_table :cas_sessions do |t|
      t.text     :service_ticket 
      t.text  :session_id
    end
  end
 
  def self.down
    drop_table :cas_sessions
  end
end

