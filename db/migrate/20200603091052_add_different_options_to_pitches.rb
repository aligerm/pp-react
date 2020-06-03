class AddDifferentOptionsToPitches < ActiveRecord::Migration[5.2]
  def change
    add_column :pitches, :pitch_sound, :boolean, default: true
    add_column :pitches, :show_ratings, :string, default: "all"
    add_column :pitches, :video_url, :string
    add_column :pitches, :skip_elections, :boolean, default: false
  end
end