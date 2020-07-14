class GameMobileController < ApplicationController
  before_action :check_game, except: [:welcome, :ended, :error]
  before_action :check_user, only: [:game, :join, :choosen, :new_name, :repeat, :send_emoji]
  before_action :check_state, only: [:game]
  before_action :check_entered, only: [:game]

  def error
  end

  def welcome
	@game = Game.where(password: params[:password], active: true).last
	if @game
	  @company = @game.company
	  game_login @game
	else
	  flash[:alert] = 'Konnte keinen passenden Pitch finden!'
	  redirect_to root_path
	end
  end

  def login
  end

  def join
  end

  def game
	@omenu = false
	@turn1 = GameTurn.find_by(id: @game.turn1) if @game.turn1
	@turn2 = GameTurn.find_by(id: @game.turn2) if @game.turn2
	@turn = GameTurn.find_by(id: @game.current_turn) if @game.current_turn
	@task = @pitch.task_orders.find_by(order: @game.current_task).task if @game.current_task != 0 && !@game.current_task.nil?
	render @state
  end

  def choosen
	if @game.state != 'choose'
	  redirect_to gm_game_path
	end
	@turn = GameTurn.find(params[:turn])
	@turn.update(counter: @turn.counter + 1)
	if @turn.id == @game.turn1
	  if @admin.avatar?
	  ActionCable.server.broadcast "count_#{@game.id}_channel", choose: true, avatar: @admin.avatar.url, site: 'left'
	  else
	  ActionCable.server.broadcast "count_#{@game.id}_channel", choose: true, name: @admin.fname[0].capitalize + @admin.lname[0].capitalize, site: 'left'
	  end
	else
	  if @admin.avatar?
	  ActionCable.server.broadcast "count_#{@game.id}_channel", choose: true, avatar: @admin.avatar.url, site: 'right'
	  else
	  ActionCable.server.broadcast "count_#{@game.id}_channel", choose: true, name: @admin.fname[0].capitalize + @admin.lname[0].capitalize, site: 'right'
	  end
	end
  end

  def upload_pitch
	@turn = GameTurn.find(params[:turn_id])
  end

  def logout
    @user = User.find(params[:turn_id])
    @turns = @game.game_turns.where(user: @user)
    @turns.each do |t|
      if t.played || t.id == @game.current_turn
        t.update(repeat: true)
      else
        t.destroy
      end
    end
    if @game.state == 'wait'
      ActionCable.server.broadcast "count_#{@game.id}_channel", remove: true, count: @game.game_turns.where(play: true).count, user_id: @user.id, state: @game.state
    end
    game_logout
    game_user_logout
    flash[:alert] = 'Du bist dem Spiel ausgetreten!'
    redirect_to root_path
    return
  end

  def ended
	if game_logged_in?
	  @game = current_game
	  @company = @game.company
	  game_logout
	  game_user_logout
	else
	  redirect_to root_path
	end
  end

  def repeat
	@game = current_game
	redirect_to gm_join_path if @admin == @game.user
  end

  def new_name
  end

  def set_timer
	if params[:timer] == 'start'
	  ActionCable.server.broadcast "game_#{@game.id}_channel", comment_timer: 'start'
	elsif params[:timer] == 'stop'
	  ActionCable.server.broadcast "game_#{@game.id}_channel", comment_timer: 'stop'
	end
  end

  def send_emoji
    if params[:emoji]
	    if @admin.avatar?
		    ActionCable.server.broadcast "count_#{@game.id}_channel", emoji: true, emoji_icon: params[:emoji], user_avatar: @admin.avatar.url
	    else
		    ActionCable.server.broadcast "count_#{@game.id}_channel", emoji: true, emoji_icon: params[:emoji], name: @admin.fname[0].capitalize + @admin.lname[0].capitalize
	    end
    elsif params[:comment]
      if @admin.avatar?
  	  	ActionCable.server.broadcast "count_#{@game.id}_channel", hide: true, comment: true, comment_text: params[:comment], comment_user_avatar: @admin.avatar.url, reverse: true
  	  else
  		  ActionCable.server.broadcast "count_#{@game.id}_channel", hide: true, comment: true, comment_text: params[:comment], name: @admin.fname[0].capitalize + @admin.lname[0].capitalize, reverse: true
  	  end
    elsif params[:emoji_comment]
      if @admin.avatar?
  	  	ActionCable.server.broadcast "count_#{@game.id}_channel", hide: true, emoji: true, emoji_icon: params[:emoji_comment], user_avatar: @admin.avatar.url, reverse: true
  	  else
        ActionCable.server.broadcast "count_#{@game.id}_channel", hide: true, emoji: true, emoji_icon: params[:emoji_comment], name: @admin.fname[0].capitalize + @admin.lname[0].capitalize, reverse: true
  	  end
    end
  end

  def repeat_turn
	@turn = GameTurn.find(@game.current_turn)
    @game.game_turns.where(task: @turn.task, user: @turn.user).each do |t|
        t.update(played: true, play: false, repeat: true)
    end
	@new_turn = GameTurn.create(game: @game, user: @turn.user, team: @turn.team, task: @turn.task, play: true, played: false)
	redirect_to gm_set_state_path('', state: 'turn')
  end

  def delete_turn
	@turn = GameTurn.find(params[:turn_id])
  @user = @turn.user
  @turns = @game.game_turns.where(user: @user)
  @turns.each do |t|
    if t.played || t.id == @game.current_turn
      t.update(repeat: true)
    else
      t.destroy
    end
  end
  if @game.state == 'wait'
    ActionCable.server.broadcast "count_#{@game.id}_channel", remove: true, count: @game.game_turns.where(play: true).count, user_id: @user.id, state: @game.state
  end
	redirect_to gm_game_path
  end

  def delete_task_user
    @turn = GameTurn.find_by(id: params[:turn_id])
    @task = @turn.task
    @order = @pitch.task_orders.find_by(task_id: @task.id)
    if @turn != @game.current_turn
      if @turn.repeat
        @turn.destroy
      else
        @turn.update(task: nil)
      end
      render json: {order: @order.order, task: @task.id}
    else
      flash[:alert] = 'Bitte warte bis der aktuelle Pitch beendet ist!'
      redirect_to gm_game_path
    end
  end
  def set_task_user
    @task = @pitch.tasks.find(params[:task_id])
    @turn = GameTurn.find_by(id: params[:turn_id])
    if @game.game_turns.where(task: @task, user: @turn.user, play: true, played: false).count == 0
      @turns = @game.game_turns.where(task: @task, play: true, played: false)
      @turns.each do |t|
        if t.repeat
          t.destroy
        else
          t.update(task: nil)
        end
      end
      if @turn.task
        @new_turn = @game.game_turns.create(user: @turn.user, team: @turn.team, task: @task, play: true, played: false, repeat: true)
        if @game.current_task == @pitch.task_orders.find_by(task: @task).order
          @game.update(current_turn: @new_turn.id, state: 'turn')
        end
      elsif !@turn.task
        @turn.update(task: @task)
        if @game.current_task == @pitch.task_orders.find_by(task: @task).order
          @game.update(current_turn: @turn.id, state: 'turn')
        end
      end
    else
      @turn = @game.game_turns.where(task: @task, user: @turn.user, play: true, played: false).first
      @game.update(current_turn: @turn.id, state: 'turn') if @game.current_task == @pitch.task_orders.find_by(task: @task).order
    end
    if params[:show_task]
      redirect_to gm_game_path
      return
    else
      redirect_to gm_game_path(slide: @pitch.task_orders.find_by(task: @task).order)
      return
    end
  end

  def set_slide
	@task_order = @pitch.task_orders.find_by(order: params[:slide])
	if @task_order
	  @game.update(current_task: params[:slide])
	  if @game.state == 'slide' && @task_order.task.task_type == 'slide'
		ActionCable.server.broadcast "game_#{@game.id}_channel", game_state: 'changed'
		redirect_to gm_game_path
		return
	  elsif @task_order.task.task_type == 'slide'
	    redirect_to gm_set_state_path(state: 'slide')
		return
	  else
		redirect_to gm_set_state_path(state: 'show_task')
		return
	  end
	else
	  redirect_to gm_set_state_path(state: 'bestlist')
	end
  end
  def set_state
    if params[:state] == 'wait'
      @game.update(state: "wait") if @game.state != 'wait'
      redirect_to gm_game_path
	    return
	  elsif params[:state] == 'slide'
	    @game.update(state: 'slide')
	    redirect_to gm_game_path
    elsif params[:state] == 'show_task'
      @task = @pitch.task_orders.find_by(order: @game.current_task).task
      @turn = GameTurn.find_by(id: @game.current_turn)
      if @turn && !@turn.played && @turn.play
		    redirect_to gm_set_state_path(state: 'turn')
		    return
      elsif @game.game_turns.find_by(task: @task, played: false)
        redirect_to gm_set_state_path(state: 'turn')
  		  return
      else
		    @turns = @game.game_turns.playable.where(task_id: nil).all
		    if @turns.count == 0
		      @turns = @game.game_turns.where(play: true, repeat: false)
		      @turns.each do |t|
			      @turn = GameTurn.create(game: @game, user: t.user, team: t.team, play: true, played: false)
			      t.update(play: false, repeat: true)
		      end
          @turns = @game.game_turns.playable.where(task_id: nil).all
          if @turns.count == 1
            redirect_to gm_set_state_path(state: 'turn')
  		      return
          else
            @turns = @game.game_turns.playable.sample(2)
  	        @task = @pitch.task_orders.find_by(order: @game.current_task)
            @game.update(state: "show_task", turn1: @turns.first.id, turn2: @turns.last.id, current_turn: nil) if @game.state != 'show_task'
  		      redirect_to gm_game_path
  	        return
          end
		    elsif @turns.count == 1
		      redirect_to gm_set_state_path(state: 'turn')
		      return
		    else
          @turns = @game.game_turns.playable.sample(2)
	        @task = @pitch.task_orders.find_by(order: @game.current_task)
          @game.update(state: "show_task", turn1: @turns.first.id, turn2: @turns.last.id, current_turn: nil) if @game.state != 'choose'
		      redirect_to gm_game_path
	        return
	      end
	    end
    elsif params[:state] == 'choose'
      @task = @pitch.task_orders.find_by(order: @game.current_task).task
      @turn = GameTurn.find_by(id: @game.current_turn)
	    if @turn && !@turn.played && @turn.play
		    redirect_to gm_set_state_path(state: 'turn')
		    return
      elsif @game.game_turns.find_by(task: @task, played: false)
        redirect_to gm_set_state_path(state: 'turn')
  		  return
      else
		    @turns = @game.game_turns.playable.where(task_id: nil).all
		    if @turns.count == 0
		      @turns = @game.game_turns.where(play: true, repeat: false)
		      @turns.each do |t|
			      @turn = GameTurn.create(game: @game, user: t.user, team: t.team, play: true, played: false)
			      t.update(played: false, play: false, repeat: true)
		      end
          @turns = @game.game_turns.playable.where(task_id: nil).all
          if @turns.count == 1
            redirect_to gm_set_state_path(state: 'turn')
  		      return
          else
            @turns = @game.game_turns.playable.sample(2)
  	        @task = @pitch.task_orders.find_by(order: @game.current_task)
            @game.update(state: "choose", turn1: @turns.first.id, turn2: @turns.last.id, current_turn: nil) if @game.state != 'choose'
  		      redirect_to gm_game_path
  	        return
          end
		    elsif @turns.count == 1
		      redirect_to gm_set_state_path(state: 'turn')
		      return
		    else
          @turns = @game.game_turns.playable.sample(2)
	        @task = @pitch.task_orders.find_by(order: @game.current_task)
          @game.update(state: "choose", turn1: @turns.first.id, turn2: @turns.last.id, current_turn: nil) if @game.state != 'choose'
		      redirect_to gm_game_path
	        return
	      end
	    end
    elsif params[:state] == 'turn'
      @turns = @game.game_turns.playable.where(task_id: nil).all
      @task = @pitch.task_orders.find_by(order: @game.current_task).task
      @turn = @game.game_turns.where(task: @task, play: true, played: false).first
	    @turn = GameTurn.find_by(id: @game.current_turn) if !@turn
	    if @turn && !@turn.played && @turn.play && @game.state != 'turn'
        @cur_turn = @turn
	    elsif @game.state != 'turn' && (@pitch.skip_elections || @turns.count == 1)
		    @cur_turn = @turns.first
      elsif @game.state == 'choose' || @game.state == 'show_task'
		    @turn1 = GameTurn.find_by(id: @game.turn1)
		    @turn2 = GameTurn.find_by(id: @game.turn2)
		    if @turn1.counter > @turn2.counter
			    @cur_turn = @turn1
		    else
          @cur_turn = @turn2
		    end
	    end
      if @cur_turn && @game.state != 'turn'
        if @cur_turn.task
          @new_turn = @game.game_turns.create(user: @cur_turn.user, team: @cur_turn.team, task: @task, play: true, played: false, repeat: true)
          @game.update(state: 'turn', current_turn: @new_turn.id)
        else
          @cur_turn.update(task: @task)
          @game.update(state: 'turn', current_turn: @cur_turn.id)
        end
      end
      redirect_to gm_game_path
	    return
    elsif params[:state] == 'play'
	    @task = @pitch.task_orders.find_by(order: @game.current_task).task
	    if @task.task_type == 'catchword'
		    @turn.update(catchword: @task.catchword_list.catchwords.sample)
	    end
      @game.update(state: 'play', turn1: nil, turn2: nil) if @game.state != 'play'
      redirect_to gm_game_path
	    return
    elsif params[:state] == 'feedback'
      @game.update(state: 'feedback') if @game.state != 'feedback'
      redirect_to gm_game_path
    elsif params[:state] == 'rate'
	    @turn = GameTurn.find_by(id: @game.current_turn)
	    if @turn
	      @task = @turn.task
        @task = @pitch.task_orders.find_by(order: @game.current_task).task if !@task
        if @task.rating1 || @task.rating2 || @task.rating3 || @task.rating4
          if @task.rating1 == '' && @task.rating2 == '' && @task.rating3 == '' && @task.rating4 == ''
            @turn.update(ges_rating: nil, played: true)
  		      redirect_to gm_set_state_path(state: 'feedback')
  		      return
          elsif @game.state != 'rate'
            @game.update(state: 'rate')
          end
        else
          @turn.update(ges_rating: nil, played: true)
		      redirect_to gm_set_state_path(state: 'feedback')
		      return
        end
		    redirect_to gm_game_path
	      return
	    else
		    redirect_to gm_game_path
		    return
	    end
    elsif params[:state] == 'rating'
      @turn = GameTurn.find_by(id: @game.current_turn)
      if @turn
        @turns = @game.game_turns.where(user_id: @turn.user_id)
        if @turns.count != 1 && @turns.find_by(ges_rating: @turns.maximum("ges_rating")) != @turn
          @bestturn = @turns.find_by(ges_rating: @turns.maximum("ges_rating"))
          @bestturn.update(play: true)
          @turn.update(play: false, played: true)
        end
        if @turn.game_turn_ratings.count == 0
          @turn.update(ges_rating: nil, played: true)
          redirect_to gm_set_slide_path(@game.current_task + 1)
          return
        elsif @pitch.show_ratings == 'none'
          @turn.update(played: true)
          redirect_to gm_set_slide_path(@game.current_task + 1)
          return
        elsif @pitch.show_ratings == 'one' && @turn_ratings.count == 0
          @turn.update(played: true)
          redirect_to gm_set_slide_path(@game.current_task + 1)
          return
        elsif  @game.state != 'rating'
          @user = @turn.user
          @turn.game_turn_ratings.each do |tr|
            @rating = @user.user_ratings.find_by(rating_criterium: tr.rating_criterium)
            new_rating = @user.game_turn_ratings.where(rating_criterium: tr.rating_criterium).average(:rating).round
            if @rating
              old_rating = @rating.rating
              @rating.update(rating: new_rating, change: new_rating - old_rating)
            else
              @user.user_ratings.create(rating_criterium: tr.rating_criterium, rating: new_rating, change: new_rating)
            end
          end
          new_rating = @user.user_ratings.average(:rating).round
          old_rating = @user.ges_rating
          @user.update(ges_rating: new_rating, ges_change: new_rating - old_rating)
          @turn.update(played: true)
          @game.update(state: 'rating')
        end
      end
      redirect_to gm_game_path
      return
    elsif params[:state] == 'bestlist'
      if @game.state != 'bestlist'
        @game.game_turns.playable.each do |gt|
          gt.update(ges_rating: nil)
        end
        @turns = @game.game_turns.where(play: true).all
        @turns = @turns.where.not(ges_rating: nil).order(ges_rating: :desc)
        place = 1
        @turns.each do |t|
          t.update(place: place)
          place += 1
        end
        @game.update(state: 'bestlist', active: false)
      end
      redirect_to gm_game_path
      return
    elsif params[:state] == 'repeat'
      if @game.state != 'repeat' && @game.state != 'wait'
        @game.update(state: 'repeat')
		    game_old = @game
		    temp = Game.where(password: @game.password, state: 'wait', active: true).first
		    temp = Game.create(company: @game.company, user: @game.user, team: @game.team, state: 'wait', active: true, password: @game.password, pitch: @game.pitch, rating_user: @game.rating_user) if @temp.nil?
      end
	    redirect_to gm_game_path
	    return
    elsif params[:state] == 'ended'
	    @game.update(state: 'ended') if @game.state != "ended"
	    redirect_to gm_game_path
	    return
	  end
  end

  def objection
	@objection = Objection.find_by(name: params[:objection])
	if @objection
	ActionCable.server.broadcast "count_#{@game.id}_channel", objection: true, objection_text: @objection.name, objection_sound: @objection.sound? ? @objection.sound.url : ""
	else
	  ActionCable.server.broadcast "count_#{@game.id}_channel", objection: true, objection_text: params[:objection], objection_sound: ""
	end
  end

  private
	def check_game
	  if game_logged_in?
		@game = current_game
        @pitch = @game.pitch
		@company = @game.company
	  else
		flash[:alert] = "Bitte trete dem Spiel zuerst bei!"
		redirect_to root_path
	  end
	end
	def check_entered
	  if game_logged_in?
		@game = current_game
		if game_user_logged_in? && @state != 'repeat'
		  @admin = current_game_user
		  if @game.game_turns.where(user: @admin, repeat: false).count == 0
			  game_logout
	  	  game_user_logout
		  	flash[:alert] = 'Du wurdest ausgeloggt!'
		  	redirect_to root_path
		  end
		end
	  end
	end
	def check_user
	  if game_user_logged_in?
		@admin = current_game_user
		@company = @admin.company
	  else
		flash[:alert] = "Bitte logge dich ein um einem Spiel beizutreten!"
		redirect_to root_path
	  end
	end

	def check_state
	  @state = @game.state
	  @turn = GameTurn.find_by(id: @game.current_turn) if @game.current_turn
	  if @state == 'repeat'
		temp = Game.where(password: @game.password, state: 'wait', active: true).first
		game_login temp
		redirect_to gm_repeat_path
	  elsif @state == 'ended'
		redirect_to gm_ended_path
	  end
	end
end
