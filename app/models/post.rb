class Post
  include Mongoid::Document
  field :title, type: String
  field :content, type: String
  field :likes, type: Integer, default: 0 #点赞数
  belongs_to :user
 
    # 点赞方法，传入一个用户对象
  def liked(user)
    # 如果在集合中添加ID成功
    if $redis.sadd "post:#{self.id.to_s}:likers", user.id.to_s
      # 那么点赞数+1  
      self.inc(likes: 1)
      # 点赞成功状态变成1，返回消息点赞成功
      {status: 1, notice: '点赞成功'}
    else
      # 否则返回状态-1，返回消息重复点赞
      {status: -1, notice: '重复点赞'}
    end
  end

  def likers
    user_ids = $redis.smembers "post:#{self.id.to_s}:likers"
    User.find(user_ids)
  end
end
