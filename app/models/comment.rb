class Comment < ApplicationRecord
  belongs_to :game_turn
  belongs_to :user
end
