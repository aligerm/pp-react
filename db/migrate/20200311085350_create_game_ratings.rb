class CreateGameRatings < ActiveRecord::Migration[5.2]
  def change
    create_table :game_ratings do |t|
      t.belongs_to :game, foreign_key: true
	  t.belongs_to :team, foreign_key: true
      t.belongs_to :rating_criterium, foreign_key: true
      t.integer :rating, default: 0

      t.timestamps
    end
  end
end
