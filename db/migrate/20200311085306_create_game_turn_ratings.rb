class CreateGameTurnRatings < ActiveRecord::Migration[5.2]
  def change
    create_table :game_turn_ratings do |t|
	  t.belongs_to :game, foreign_key: true
      t.belongs_to :game_turn, foreign_key: true
      t.belongs_to :user, foreign_key: true
      t.belongs_to :rating_criterium, foreign_key: true
      t.integer :rating, default: 0

      t.timestamps
    end
  end
end
