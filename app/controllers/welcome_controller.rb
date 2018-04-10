class WelcomeController < ApplicationController
  def index
  	# 访问index页面发送请求创建自定义菜单
  	menu = {
     "button":[
     {    
          "type": "click",
          "name": "签到",
          "key": "SIGN_IN" 
      },
      {
           "name": "菜单",
           "sub_button": [
            {
              "type": "view",
              "name": "今日热点",
              "url": "https://www.toutiao.com/"
              },
           {    
               "type": "view",
               "name": "搜索",
               "url": "http://www.baidu.com/"
            },
            {
              "type": "view",
              "name": "🎲损友圈",
              "url": "http://play.wxavu.com/game/?gameid=261&share_from=msg&fuid=311379278&statid=1602&cp_from=msg&cp_shareId=41/"
            },
            {
               "type": "click",
               "name": "点赞",
               "key": "LIKE"
            }]
     },
     { 
       	   "name": "关于我",
    		   "sub_button":[
          	{
    		       "type": "click",
    		       "name": "查看点赞数",
    		       "key": "LIKE_COUNT"
    				
    	      },
            {
              "type": "click",
              "name": "联系我们",
              "key": "CONNECT_US"
            },
            {	
        	  "type": "click",
        	  "name": "个人中心",
        	  "key": "USER"
            }]
     }
       ]
 }

   	response = $client.create_menu(menu) # Hash or Json
   	# 响应输出在页面显示出来
    logger.debug response 
    # 返回json格式的响应
		render json: response
  end
end
