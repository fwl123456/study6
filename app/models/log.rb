class Log # 签到
  include Mongoid::Document
  include Mongoid::Timestamps
  # 积分
  field :credit, type: Integer
  belongs_to :user # 积分属于用户
end
