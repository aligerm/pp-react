class LandingController < ApplicationController
  layout 'landing'
  before_action :check_user
	
  def index
  end
	
  def product
  end
	
  def contact
  end
	
  def blogs
  end
	
  def impressum
  end
	
  def datenschutz
  end
	
  def new_password
  end
	
  def accept_cookie
	cookies[:accepted] = 'true'
	redirect_to root_path
  end
	
  private
    def check_user
	  if user_signed_in?
		redirect_to dashboard_path
	  elsif User.where(bo_role: 'root').count == 0
		@company = Company.find_by(name: 'Peter Pitch GmbH')
		@company = Company.create(name: 'Peter Pitch GmbH', activated: true) if @company.nil?
		password = SecureRandom.urlsafe_base64(8)
		@user = @company.users.create(fname: 'Jan Philipp', lname: 'Resing', role: 'company_admin', bo_role: 'root', email: 'resing@peterpitch.com', password: password)
		UserMailer.after_create(@user, password).deliver
	  end
	end
end
