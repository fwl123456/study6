# 关注后任务 将用户信息写入user表
class UserSubscribeJob < ApplicationJob
  queue_as :default 
  def perform(openid)
    # 传入openid拿到用户个人信息
      message = $client.user(openid)
      user = User.create(message.result)
  end
end
