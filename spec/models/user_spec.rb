require 'rails_helper'

RSpec.describe User, type: :model do

  describe '验证' do
    before :each do
      # 运行下面测试之前先new一个空的user对象
      @user = build(:user, nickname: '')
    end
    it '用户名不能为空' do
      #user验证返回false 因为名字为空
      expect(@user.valid?).to be false
      # user里面的错误中nickname为true  true为空  false为不空
      expect(@user.errors[:nickname].any?).to be true
      # user错误中nickname返回的错误消息是不得为空
      expect(@user.errors[:nickname].first).to eq "can't be blank"
    end
  end

  describe '签到' do
    before :each do
      # 运行下面测试前先创建一个user用户
      @user = create(:user)
    end

    it '查看当前积分' do
      # 没人签到时签积分是0
      expect(@user.credit).to eq 0
    end

    it '每日签到' do
      # 用户签到后积分和状态用result装起来
      result = @user.sign_in
      # 用户积分等于积分
      old_credit = @user.credit
      # 状态是1 ，1 为签到成功
      expect(result[:status]).to eq 1
      # 用户积分就等于result里面的积分
      expect(@user.credit).to eq result[:credit].to_i
    end

    it '重复签到' do
      # 用户签到后积分和状态用result装起来
      result = @user.sign_in
      # 用户积分就等于result里面的积分
      expect(@user.credit).to eq result[:credit].to_i
      # 用户重复签到
      result1 = @user.sign_in
      # result里状态为-1  签到失败
      expect(result1[:status]).to eq -1
      # 用户积分还是等于result里面的积分
      expect(@user.credit).to eq result[:credit].to_i
    end

    it '连续三天签到' do
      # 用户第一天签到
      result = @user.sign_in
      result = @user.sign_in
      allow(Time).to receive(:now).and_return Time.now + 1.day
      allow(Date).to receive(:today).and_return Date.today + 1.day
      # 用户第二天签到
      result = @user.sign_in
      result = @user.sign_in
      allow(Time).to receive(:now).and_return Time.now + 1.day
      allow(Date).to receive(:today).and_return Date.today + 1.day
      # 用户第三天签到  
      result = @user.sign_in
      result = @user.sign_in
      # 积分每次签到为3分，三次签到就是9分
      expect(@user.credit).to eq 9
    end

  end
end
