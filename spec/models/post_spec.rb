require 'rails_helper'

RSpec.describe Post, type: :model do
  describe '点赞' do
    before :each do
      # 点赞需要user对象，文章对象 
      @user = create(:user)
      @post = create(:post, user: @user)
      @user1 = create(:user, nickname: 'bobo')
    end
    it '查看点赞数' do
      # 没人点赞时，点赞数为0
      expect(@post.likes).to eq 0
    end

    it '被用户点赞' do 
      # 用户点赞
      result = @post.liked(@user)
      expect(result[:status]).to eq 1
      expect(@post.likes).to eq 1
    end

    it '被用户重复点赞' do
    #  用户点赞
      result = @post.liked(@user)
    # 点赞成功状态1，点赞数变成1
      expect(result[:status]).to eq 1
      expect(@post.likes).to eq 1
    # 用户重复点赞
      result = @post.liked(@user)
    # 重复点赞后状态变成-1，点赞数还是1
      expect(result[:status]).to eq -1
      expect(@post.likes).to eq 1
    end

    it '被多用户点赞' do
      # user用户点赞3次
      @post.liked(@user)
      @post.liked(@user)
      @post.liked(@user)
      # user1用户点赞2次
      @post.liked(@user1)
      @post.liked(@user1)
      # 文章点赞数 2次
      expect(@post.likes).to eq 2
    end

   it '列出所有点赞用户' do
    # 两个用户给文章点赞
    @post.liked(@user)
    @post.liked(@user1)
    # 预计文章点赞者里面包含用户和用户1
    expect(@post.likers).to eq [@user, @user1]
    # # 2个用户点赞 $redis.sadd "post:#{self.id.to_s}:likers", user.id.to_s

    # likers = $redis.smembers "post:#{@post.id.to_s}:likers"
    # expect(likers.count).to eq 2



     # # 先拿到点赞中的用户id
     # user_ids = post.likes.user_id
     # # 从用户中通过id找到跟点赞中id一样的所有用户
     # users = User.where(id: user_ids)
     # users.each do |user|
     # user.nickname
     
   end

 end
end
