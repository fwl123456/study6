json.extract! user, :id, :nickname, :openid, :headimgurl, :created_at, :updated_at
json.url user_url(user, format: :json)
