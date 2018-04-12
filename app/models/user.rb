class User
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  field :nickname, type: String
  field :openid, type: String
  field :headimgurl, type: String
  field :credit, type: Integer, default: 0  # 积分
  has_many :posts
  has_many :logs 

  validates :nickname, presence: true

# 签到功能
  def sign_in
  	# 判断如果在签到中里面找到签到创建时间是在今天范围内的话
    if self.logs.between(created_at: [Date.today.beginning_of_day, Date.today.end_of_day]).any?
      # 返回状态 -1，提示你已经签到过了，请明天再来
      {status: -1, notice: '你已经签到过了，请明天再来！'}
    else
    	# 否者签到积分增加3
      self.inc(credit: 3)
      # 创建用户签到表，里面积分为3分保存起来
      self.logs.create(credit: 3)
      # 返回状态为1，
      {status: 1, notice: '恭喜你签到成功', credit: 3}
    end
  end
end
