class WorklogForm
  include Virtus.model
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attribute :worklog, Worklog
  attribute :user, User
  attribute :timeframes, Array
  attribute :hourly_rate, Numeric
  attribute :comment, String, default: ""

  validates :hourly_rate, numericality: {greater_than: 0}
  validates :comment, presence: true
  validate :timeframes_validator

  def self.new_from_params(params, user: nil, worklog: nil)
    obj = new(params)
    obj.user = user
    obj.worklog = worklog
    obj
  end

  def save
    if valid?
      wl = worklog || to_worklog
      wl = assign_new_attributes(wl)
      wl.save!
    else
      false
    end
  end

  def timeframes=(new_timeframes)
    result = []
    if new_timeframes.is_a? Array
      new_timeframes.each do |tf|
        if tf.is_a? Timeframe
          result << tf
        else
          result << Timeframe.new(tf)
        end
      end
    else
      result = new_timeframes
    end
    super result
  end

  def assign_new_attributes(use_worklog)
    use_worklog.hourly_rate = hourly_rate
    use_worklog.summary = comment
    use_worklog
  end

  def to_worklog
    wl = Worklog.new
    wl
  end

  private

  def timeframes_validator
    if timeframes.blank?
      errors.add :timeframes, "Must be present"
      return
    end

    unless timeframes.all? {|tf| tf.valid? }
      errors.add :timeframes, "Some of the timeframes are not valid"
      tf = timeframes.find {|tf| !tf.valid? }
      # Add first timeframe messages errors.
      errors.add :timeframes, tf.errors.full_messages_joined
    end
  end

  def timeframes_correct_start_end_time?
    timeframes.any? {|tf| t}
  end

end