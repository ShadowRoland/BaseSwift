添加分享的sdk库文件
================
按照目录下载和添加第三方社交软件的sdk库文件（同时按照sdk的说明文档检查需要添加的系统framework），然后在相应的官网注册Application并取得对应的appid
国内常见的第三方社交软件包括:

QQ
---------
[官方sdk地址](http://wiki.open.qq.com/wiki/IOS_API%E8%B0%83%E7%94%A8%E8%AF%B4%E6%98%8E)

文件列表（最新版参考官方文档）:
* TencentOpenApi/
	* TencentOpenApi_IOS_Bundle.bundle
	* TencentOpenAPI.framework

微信
---------------------
[官方sdk地址](https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=open1419319164&token=&lang=zh_CN)

文件列表（最新版参考官方文档），该sdk集成了微信分享、登录、收藏、支付等功能:
* libWeChatSDK/
	* libWeChatSDK.a
	* WechatAuthSDK.h
	* WXApi.h
	* WXApiObject.h

微博
---------------------
[官方sdk说明](http://open.weibo.com/wiki/SDK#iOS_SDK)

文件列表（最新版参考官方文档）:
* libWeiboSDK/
	* libWeiboSDK.a
	* WeiboSDK.bundle
	* WBHttpRequest+WeiboToken.h
	* WBHttpRequest.h
	* WeiboSDK+Statistics.h
	* WeiboSDK.h
