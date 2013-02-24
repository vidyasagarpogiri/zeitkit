class WorklogsController < ApplicationController
  load_and_authorize_resource

  def index
    @user = User.find(params[:user_id])
    @worklogs = @worklogs.order("start_time DESC")
    @clients = @user.clients
    params[:client] ? @worklogs = @worklogs.where(client_id: params[:client]) : @worklogs
    params[:paid] == "true" ? @worklogs = @worklogs.paid : @worklogs
    params[:paid] == "false" ? @worklogs = @worklogs.unpaid : @worklogs
    params[:time] == "today" ? @worklogs = @worklogs.today : @worklogs
    params[:time] == "this_week" ? @worklogs = @worklogs.this_week : @worklogs
    params[:time] == "this_month" ? @worklogs = @worklogs.this_month : @worklogs
    params[:time] == "last_month" ? @worklogs = @worklogs.last_month : @worklogs
    @sum = Money.new @worklogs.sum(:total_cents), @user.currency
    seconds = Worklog.range_duration_seconds(@worklogs)
    @hours = Worklog.hours_from_seconds seconds
    @minutes = Worklog.remaining_minutes_from_seconds seconds

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @worklogs }
      format.csv { render text: @worklogs.to_csv(@worklogs) }
    end
  end

  def show
    @worklog = Worklog.find(params[:id])
  end

  def new
    @worklog = Worklog.new
    @worklog.user = current_user
    @worklog.client = current_user.worklogs.any? ? current_user.worklogs.last.client : nil
    params[:client] ? @worklog.client = current_user.clients.find(params[:client]) : nil
    @start_time_save = current_user.check_or_build_start_time
    if params[:recover_time]
      @worklog.start_time = @start_time_save.start_time
      flash.now[:notice] = "Successfully restored the start time: #{l @start_time_save.start_time}."
      @start_time_save = nil
    end
  end

  def edit
  end

  def create
    @worklog = Worklog.new(params[:worklog])
    @worklog.user = current_user
    if @worklog.save
      redirect_to new_user_worklog_path,
        notice: "Worklog was successfully created. Create another one - or: <a href='#{user_worklogs_path}'>Go back.</a>".html_safe
    else
      render action: "new"
    end
  end

  def update
    if @worklog.update_attributes(params[:worklog])
      redirect_to user_worklogs_path(current_user), notice: 'Worklog was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @worklog.destroy
    redirect_to user_worklogs_path(current_user)
  end

  def toggle_paid
    @worklog.toggle_paid
    if @worklog.save
      redirect_to user_worklogs_path(current_user, params[:old_params]), notice: 'Worklog was successfully updated.'
    else
      render action: "edit"
    end
  end
end
