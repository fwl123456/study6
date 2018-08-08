# encoding: utf-8
# 1, @weixin_message: 获取微信所有参数.
# 2, @weixin_public_account: 如果配置了public_account_class选项,则会返回当前实例,否则返回nil.
# 3, @keyword: 目前微信只有这三种情况存在关键字: 文本消息, 事件推送, 接收语音识别结果
WeixinRailsMiddleware::WeixinController.class_eval do

  def reply
    render xml: send("response_#{@weixin_message.MsgType}_message", {})
  end

  def get_access_token
    response = Typhoeus.get("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{get_app_id}&secret=#{get_app_secret}")
    response_json=JSON.parse(response.options[:response_body])  
    response_json["access_token"]  
  end

  private
    # 发送文本消息响应
    def response_text_message(options={})
      case @keyword
      when '新建文章'
        reply_text_message("请输入文章标题:文章内容")
      when /(.+):(.+)/
        match = /(.+):(.+)/.match(@keyword)
        post = Post.create(title: match[1], content: match[2])
        reply_text_message("文章建立完成: #{post.title}:#{post.content}") 
      when '查看文章'
        puts Post.all.count
        @posts = Post.all
        @posts.each do |p|
          puts p.title
          $client.send_text_custom(@weixin_message.FromUserName, p.title)
        end
        # Post.all.each do |post|
          reply_text_message("文章已全部发送")
        # end
      else
        # 否则返回用户发的信息
        reply_text_message("Your Message: #{@keyword}")
      end
    end

    # <Location_X>23.134521</Location_X>
    # <Location_Y>113.358803</Location_Y>
    # <Scale>20</Scale>
    # <Label><![CDATA[位置信息]]></Label>
    def response_location_message(options={})
      @lx    = @weixin_message.Location_X
      @ly    = @weixin_message.Location_Y
      @scale = @weixin_message.Scale
      @label = @weixin_message.Label
      reply_text_message("Your Location: #{@lx}, #{@ly}, #{@scale}, #{@label}")
    end

    # <PicUrl><![CDATA[this is a url]]></PicUrl>
    # <MediaId><![CDATA[media_id]]></MediaId>
    def response_image_message(options={})
      @media_id = @weixin_message.MediaId # 可以调用多媒体文件下载接口拉取数据。
      @pic_url  = @weixin_message.PicUrl  # 也可以直接通过此链接下载图片, 建议使用carrierwave.
      reply_image_message(generate_image(@media_id))
      # reply_text_message("Your image: #{@pic_url}")
    end

    # <Title><![CDATA[公众平台官网链接]]></Title>
    # <Description><![CDATA[公众平台官网链接]]></Description>
    # <Url><![CDATA[url]]></Url>
    def response_link_message(options={})
      @title = @weixin_message.Title
      @desc  = @weixin_message.Description
      @url   = @weixin_message.Url
      reply_text_message("回复链接信息")
    end

    # <MediaId><![CDATA[media_id]]></MediaId>
    # <Format><![CDATA[Format]]></Format>
    def response_voice_message(options={})
      @media_id = @weixin_message.MediaId # 可以调用多媒体文件下载接口拉取数据。
      @format   = @weixin_message.Format
      # 如果开启了语音翻译功能，@keyword则为翻译的结果
      # reply_text_message("回复语音信息: #{@keyword}")
      reply_voice_message(generate_voice(@media_id))
    end

    # def response_shortvideo_message(options={})
    #   @media_id = @weixin_message.MediaId
    #   @thumb_media_id = @weixin_message.ThumbMediaId
    #   reply_shortvideo_message('#{@media_id}')
    # end

    # <MediaId><![CDATA[media_id]]></MediaId>
    # <ThumbMediaId><![CDATA[thumb_media_id]]></ThumbMediaId>
    def response_video_message(options={})
      @media_id = @weixin_message.MediaId # 可以调用多媒体文件下载接口拉取数据。
      # 视频消息缩略图的媒体id，可以调用多媒体文件下载接口拉取数据。
      @thumb_media_id = @weixin_message.ThumbMediaId
      reply_text_message("回复视频信息")
    end

    def response_event_message(options={})
      event_type = @weixin_message.Event
      method_name = "handle_#{event_type.downcase}_event"
      if self.respond_to? method_name, true
        send(method_name)
      else
        send("handle_undefined_event")
      end
    end

    # 关注公众账号
    def handle_subscribe_event 
      UserSubscribeJob.perform_later openid
      if @keyword.present?
        # 扫描带参数二维码事件: 1. 用户未关注时，进行关注后的事件推送
        return reply_text_message("扫描带参数二维码事件: 1. 用户未关注时，进行关注后的事件推送, keyword: #{@keyword}")
      end
      reply_text_message("感谢您的关注")
    end

    # 取消关注
    def handle_unsubscribe_event
      Rails.logger.info("取消关注")
    end

    # 扫描带参数二维码事件: 2. 用户已关注时的事件推送
    def handle_scan_event
      reply_text_message("扫描带参数二维码事件: 2. 用户已关注时的事件推送, keyword: #{@keyword}")
    end

    def handle_location_event # 上报地理位置事件
      @lat = @weixin_message.Latitude
      @lgt = @weixin_message.Longitude
      @precision = @weixin_message.Precision
      article = []
      article << generate_article('title', 'desc', 'https://avatars3.githubusercontent.com/u/37606189?s=40&v=4', 'http://baidu.com')
      article << generate_article('新浪', 'desc', 'https://i.loli.net/2018/08/06/5b68056b47417.png', 'https://weibo.com/login.php?sudaref=www.google.com&display=0&retcode=6102')
      # 回复图文消息
      reply_news_message(article)
      #reply_text_message("Your Location: #{@lat}, #{@lgt}, #{@precision}")
    end

    # 点击事件
    # 签到按钮点击事件
    def handle_click_sign_in_event(weixin_message)
      openid = @weixin_message.FromUserName
      if $redis.sadd('users:sign_in', openid)
          reply_text_message("恭喜你签到成功，积分+1")
        else
          reply_text_message("您已经签到过了，请明天再来")
      end
    end

    def handle_click_like_event(weixin_message)
      # 拿到点击用户openID
      openid = @weixin_message.FromUserName
      # 判断用户如果点赞成功,返回文本消息
      if $redis.sadd('users:like_counts', openid)
          reply_text_message("感谢您的支持，点赞数+1")
        else
      # 否则返回你已经 点赞过了
          reply_text_message("您已经点赞过了")
      end
    end

    def handle_click_like_count_event(weixin_message)
      like_count = $redis.scard 'users:like_counts'
      reply_text_message("已有#{like_count}人为本站点赞")
    end
    # 点击联系我们事件：
    def handle_click_connect_us_event(weixin_message)
      reply_image_message(generate_image("dT3iS-b09AmaSMFvgusPUcC3qJyLp86Z8uEYuh1foHBo8kRzzufcZ_37B8EWitcA"))
    end
    # 点击其他事件：
    def handle_click_other_event(weixin_message)
    # 返回图文消息
      article = []
      article << generate_article('title', 'desc', 'https://avatars3.githubusercontent.com/u/37606189?s=40&v=4', 'http://baidu.com')
      article << generate_article('新浪', 'desc', 'https://i.loli.net/2018/08/06/5b68056b47417.png', 'https://weibo.com/login.php?sudaref=www.google.com&display=0&retcode=6102')
      # 回复图文消息
      reply_news_message(article)
      # reply_image_message(generate_image("4B6erJvpc5QVRPBaU5rvQlRqbA_5g0aRDHSTyh9B-wCfmo-O25nslS-3iCogk9eR"))
    end

    # 其他点击事件
    def method_missing(m, *args, &block)  
      puts "There's no method called #{m} here -- please try again."  
      reply_text_message("开发中,敬请期待!!!")
      # ngO_st_z0i3Ml0hpjKGZ15E9aTKo3BMABSmf11A06XeclzClEHwvRD3o7d9g-RtO
      # reply_image_message(generate_image("4B6erJvpc5QVRPBaU5rvQlRqbA_5g0aRDHSTyh9B-wCfmo-O25nslS-3iCogk9eR"))
    end 

    # 点击菜单拉取消息时的事件推送
    def handle_click_event
      logger.debug(@keyword)
      send("handle_click_#{@keyword.downcase}_event", @weixin_message)
      # reply_image_message("#{@keyword}")
      # reply_image_message(generate_image("ngO_st_z0i3Ml0hpjKGZ15E9aTKo3BMABSmf11A06XeclzClEHwvRD3o7d9g-RtO"))
    end

    # 点击菜单跳转链接时的事件推送
    def handle_view_event
      Rails.logger.info("你点击了: #{@keyword}")
    end

    # 帮助文档: https://github.com/lanrion/weixin_authorize/issues/22

    # 由于群发任务提交后，群发任务可能在一定时间后才完成，因此，群发接口调用时，仅会给出群发任务是否提交成功的提示，若群发任务提交成功，则在群发任务结束时，会向开发者在公众平台填写的开发者URL（callback URL）推送事件。

    # 推送的XML结构如下（发送成功时）：

    # <xml>
    # <ToUserName><![CDATA[gh_3e8adccde292]]></ToUserName>
    # <FromUserName><![CDATA[oR5Gjjl_eiZoUpGozMo7dbBJ362A]]></FromUserName>
    # <CreateTime>1394524295</CreateTime>
    # <MsgType><![CDATA[event]]></MsgType>
    # <Event><![CDATA[MASSSENDJOBFINISH]]></Event>
    # <MsgID>1988</MsgID>
    # <Status><![CDATA[sendsuccess]]></Status>
    # <TotalCount>100</TotalCount>
    # <FilterCount>80</FilterCount>
    # <SentCount>75</SentCount>
    # <ErrorCount>5</ErrorCount>
    # </xml>
    def handle_masssendjobfinish_event
      Rails.logger.info("回调事件处理")
    end

    # <xml>
    # <ToUserName><![CDATA[gh_7f083739789a]]></ToUserName>
    # <FromUserName><![CDATA[oia2TjuEGTNoeX76QEjQNrcURxG8]]></FromUserName>
    # <CreateTime>1395658920</CreateTime>
    # <MsgType><![CDATA[event]]></MsgType>
    # <Event><![CDATA[TEMPLATESENDJOBFINISH]]></Event>
    # <MsgID>200163836</MsgID>
    # <Status><![CDATA[success]]></Status>
    # </xml>
    # 推送模板信息回调，通知服务器是否成功推送
    def handle_templatesendjobfinish_event
      Rails.logger.info("回调事件处理")
    end

    # <xml>
    # <ToUserName><![CDATA[toUser]]></ToUserName>
    # <FromUserName><![CDATA[FromUser]]></FromUserName>
    # <CreateTime>123456789</CreateTime>
    # <MsgType><![CDATA[event]]></MsgType>
    # <Event><![CDATA[card_pass_check]]></Event>  //不通过为card_not_pass_check
    # <CardId><![CDATA[cardid]]></CardId>
    # </xml>
    # 卡券审核事件，通知服务器卡券已(未)通过审核
    def handle_card_pass_check_event
      Rails.logger.info("回调事件处理")
    end

    def handle_card_not_pass_check_event
      Rails.logger.info("回调事件处理")
    end

    # <xml>
    # <ToUserName><![CDATA[toUser]]></ToUserName>
    # <FromUserName><![CDATA[FromUser]]></FromUserName>
    # <FriendUserName><![CDATA[FriendUser]]></FriendUserName>
    # <CreateTime>123456789</CreateTime>
    # <MsgType><![CDATA[event]]></MsgType>
    # <Event><![CDATA[user_get_card]]></Event>
    # <CardId><![CDATA[cardid]]></CardId>
    # <IsGiveByFriend>1</IsGiveByFriend>
    # <UserCardCode><![CDATA[12312312]]></UserCardCode>
    # <OuterId>0</OuterId>
    # </xml>
    # 卡券领取事件推送
    def handle_user_get_card_event
      Rails.logger.info("回调事件处理")
    end

    # <xml>
    # <ToUserName><![CDATA[toUser]]></ToUserName>
    # <FromUserName><![CDATA[FromUser]]></FromUserName>
    # <CreateTime>123456789</CreateTime>
    # <MsgType><![CDATA[event]]></MsgType>
    # <Event><![CDATA[user_del_card]]></Event>
    # <CardId><![CDATA[cardid]]></CardId>
    # <UserCardCode><![CDATA[12312312]]></UserCardCode>
    # </xml>
    # 卡券删除事件推送
    def handle_user_del_card_event
      Rails.logger.info("回调事件处理")
    end

    # <xml>
    # <ToUserName><![CDATA[toUser]]></ToUserName>
    # <FromUserName><![CDATA[FromUser]]></FromUserName>
    # <CreateTime>123456789</CreateTime>
    # <MsgType><![CDATA[event]]></MsgType>
    # <Event><![CDATA[user_consume_card]]></Event>
    # <CardId><![CDATA[cardid]]></CardId>
    # <UserCardCode><![CDATA[12312312]]></UserCardCode>
    # <ConsumeSource><![CDATA[(FROM_API)]]></ConsumeSource>
    # </xml>
    # 卡券核销事件推送
    def handle_user_consume_card_event
      Rails.logger.info("回调事件处理")
    end

    # <xml>
    # <ToUserName><![CDATA[toUser]]></ToUserName>
    # <FromUserName><![CDATA[FromUser]]></FromUserName>
    # <CreateTime>123456789</CreateTime>
    # <MsgType><![CDATA[event]]></MsgType>
    # <Event><![CDATA[user_view_card]]></Event>
    # <CardId><![CDATA[cardid]]></CardId>
    # <UserCardCode><![CDATA[12312312]]></UserCardCode>
    # </xml>
    # 卡券进入会员卡事件推送
    def handle_user_view_card_event
      Rails.logger.info("回调事件处理")
    end

    # <xml>
    # <ToUserName><![CDATA[toUser]]></ToUserName>
    # <FromUserName><![CDATA[FromUser]]></FromUserName>
    # <CreateTime>123456789</CreateTime>
    # <MsgType><![CDATA[event]]></MsgType>
    # <Event><![CDATA[user_enter_session_from_card]]></Event>
    # <CardId><![CDATA[cardid]]></CardId>
    # <UserCardCode><![CDATA[12312312]]></UserCardCode>
    # </xml>
    # 从卡券进入公众号会话事件推送
    def handle_user_enter_session_from_card_event
      Rails.logger.info("回调事件处理")
    end

    # <xml>
    # <ToUserName><![CDATA[toUser]]></ToUserName>
    # <FromUserName><![CDATA[fromUser]]></FromUserName>
    # <CreateTime>1408622107</CreateTime>
    # <MsgType><![CDATA[event]]></MsgType>
    # <Event><![CDATA[poi_check_notify]]></Event>
    # <UniqId><![CDATA[123adb]]></UniqId>
    # <PoiId><![CDATA[123123]]></PoiId>
    # <Result><![CDATA[fail]]></Result>
    # <Msg><![CDATA[xxxxxx]]></Msg>
    # </xml>
    # 门店审核事件推送
    def handle_poi_check_notify_event
      Rails.logger.info("回调事件处理")
    end

    # 未定义的事件处理
    def handle_undefined_event
      Rails.logger.info("回调事件处理")
    end

end
