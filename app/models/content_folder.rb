class ContentFolder < ApplicationRecord
  belongs_to :company, required: false
  belongs_to :department, required: false
  belongs_to :team, required: false
  belongs_to :user
  belongs_to :content_folder, required: false
  has_many :content_folders
  has_many :task_media

  def self.search(search)
    if search
      where('lower(name) LIKE ?', "%#{search.downcase}%")
    else
      scoped
    end
  end
end
