class Task < ApplicationRecord
	belongs_to :company, required: false
	belongs_to :department, required: false
	belongs_to :team, required: false
  	belongs_to :user
	belongs_to :task_medium, required: false
	belongs_to :catchword_list, required: false
	belongs_to :objection_list, required: false
	belongs_to :rating_list, required: false
	has_many :task_orders, dependent: :destroy
	has_many :pitches, through: :task_orders

	before_save do
		user = User.find(self.user_id)
		self.company_id = user.company_ids.first if self.company_id.nil?
	end
	after_save do
		if self.task_type == 'slide' && self.task_medium
			self.update(valide: true) if !self.valide
		elsif self.title.present?
			if self.task_type == 'catchword' && self.catchword_list&.catchwords.present?
				self.update(valide: true) if !self.valide
			elsif self.task_medium && self.task_medium.media_type == 'audio' && self.task_medium.audio?
				self.update(valide: true) if !self.valide
			elsif self.task_medium && self.task_medium.media_type == 'image' && self.task_medium.image?
				self.update(valide: true) if !self.valide
			elsif self.task_medium && self.task_medium.media_type == 'video' && self.task_medium.video?
				self.update(valide: true) if !self.valide
			else
				self.update(valide: false) if self.valide
			end
	  else
		  self.update(valide: false) if self.valide
	  end
	end
    private

    def format_json_values value
        JSON(value)
    end
end
