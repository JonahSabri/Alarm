
chats = {}
package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  .. ';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

--- Libs ---
http = require("socket.http")
https = require("ssl.https")
http.TIMEOUT = 10
JSON = require('./req/dkjson')
json = (loadfile "./req/JSON.lua")()
tdcli = require './req/tdcli'
redis = (loadfile "./req/redis.lua")()
serpent = require('./req/serpent')
serp = require './req/serpent'.block
--- * ---

if redis:get("ontime") then
---
else
redis:set("ontime", 1200)
end
if redis:hget("timer", 'secend') then
---
else
redis:hset("timer", 'secend', 0)
end
if redis:hget("timer", 'minute') then
---
else
redis:hset("timer", 'minute', 20)
end
if redis:hget("timer", 'hours') then
---
else
redis:hset("timer", 'hours', 0)
end
if redis:get("realm") then
---
else
redis:set("realm", 123456789)
end

-------Sudo Users -----------
sudo = {
  201704410,
 
}

--- * ---


-------- Get Realm--------
realm = tonumber(redis:get("realm"))
--- * ---

--------- Is Sudo ---------
function is_sudo(msg)
  local var = false
  for v,user in pairs(sudo) do
    if user == msg.sender_user_id_ then
      var = true
    end
  end
  return var
end

--- * ---

local function vardump(value)
  --print(serpent.block(value, {comment=false}))
end

function dl_cb(arg, data)
vardump(data)
end

--- Get Username From Id ---

function get_user(arg, data)
	vardump(data)
	local url , res = http.request('http://irapi.ir/time/')
	if res ~= 200 then
		return
	end
	local jdat = json:decode(url)

	if (data.username_) then
		if redis:sismember("vipusers", data.id_) or redis:get("onlinemode") then
			if redis:get("nexton:"..data.id_) then
				---
			else
				timer = redis:get("ontime")
				tdcli.sendText(realm, 0, 0, 1, nil, "#OnlineStatus\n〰〰〰〰\n🔛 Name : ( "..data.first_name_.." )\n🔛 Username : ( @"..data.username_.." )\n\n⏱ Time : ( "..jdat.ENtime.." )", 1, 'html')
				redis:setex("nexton:"..data.id_, tonumber(timer), true)
			end
		end

	else

		if redis:sismember("vipusers", data.id_) or redis:get("onlinemode") then
			if redis:get("nexton:"..data.id_) then
				---
			else
				timer = redis:get("ontime")
				tdcli.sendText(realm, 0, 0, 1, nil, "#OnlineStatus\n〰〰〰〰\n🔛 Name : ( "..data.first_name_.." )\n🔛 Username : ( Null )\n\n⏱ Time : ( "..jdat.ENtime.." )", 1, 'html')
				redis:setex("nexton:"..data.id_, tonumber(timer), true)
			end
		end
	end
end
--- * ---


------------ Get Messages -----------

function tdcli_update_callback(data)
	if (data.ID == "UpdateUserStatus") then
		if data.status_.ID == "UserStatusOnline" then
			tdcli_function ({
				ID = "GetUser",
				user_id_ = data.user_id_
			}, get_user, nil)
		end

  elseif (data.ID == "UpdateNewMessage") then

		local msg = data.message_
    local cmd = msg.content_.text_
    local chat_id = msg.chat_id_
    local user_id = msg.sender_user_id_
    local reply_id = msg.reply_to_message_id_

    if msg.content_.ID == "MessageText" then
    	if cmd:match("^[/!#]setrealm") and is_sudo(msg) then
    		if (redis:get("realm")) == msg.chat_id_ then
					tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, 'This Chat is *Already* Realm', 1, 'md')
				else
					tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, 'Realm Changed To : '..msg.chat_id_.."Relunch Bot For Reload Settings", 1, 'md')
					redis:set("realm", msg.chat_id_)
				end
			end
    		if cmd:match("^[/!#]onlinemode (.*)") and is_sudo(msg) then
					local ap = {string.match(cmd, "^([/!#]onlinemode) (.*)$")}
      		if ap[2] == "on" then
						redis:set("onlinemode", true)
						tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, 'Online Mode Set To : *On*', 1, 'md')
					elseif ap[2] == "off" then
						tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, 'Online Mode Set To : *Off*', 1, 'md')
						redis:del("onlinemode")
     			end
   			end

			if cmd:match("^[/!#]settime (%d+) (%d+) (%d+)") and is_sudo(msg) then
				local ap = {string.match(cmd, "^([/!#]settime) (%d+) (%d+) (%d+)$")}
				local ap1 = ap[2]
				local ap2 = ap[3]
				local plus = ap1*3600 + ap2*60 + ap[4]
				redis:set("ontime", plus)
				redis:hset("timer", 'secend', ap[4])
				redis:hset("timer", 'minute', ap[3])
				redis:hset("timer", 'hours', ap[2])
				tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, '⏱ Online Status Time *Change* To : \n( '..ap1..' ) Hours\n( '..ap2..' ) Minute\n( '..ap[4]..' ) Secend', 1, 'md')
			end
			if cmd:match("^[/!#]delcontact @(.*)") and is_sudo(msg) then
				local ap = {string.match(cmd, "^([/!#]delcontact) @(.*)$")}
				function delcontact(extra, result, success)
					if result.id_ then
						if redis:sismember("vipusers", result.id_) then
							redis:srem("vipusers", result.id_)
							tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "➿ User : "..result.id_.."\n*Deleted* From VIP users", 1, 'md')
         		else
							tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "➿ User : "..result.id_.."\n*Not Added* To VIP users", 1, 'md')
						end
					else
						tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, 'User *Not Found*', 1, 'md')
					end
				end
			tdcli_function ({
				ID = "SearchPublicChat",
				username_ = ap[2]
			}, delcontact, nil)

		end

		if cmd:match("^[/!#]setvip @(.*)") and is_sudo(msg) then
			local ap = {string.match(cmd, "^([/!#]setvip) @(.*)$")}
			function setcontact(extra, result, success)
				if result.id_ then
	  			if redis:sismember("vipusers", result.id_) then
						tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "➿ User : "..result.id_.."\n*Already* Added To VIP users", 1, 'md')
					else
						redis:sadd("vipusers", result.id_)
						tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "➿ User : "..result.id_.."\n*Added* To VIP users", 1, 'md')
				  end
				else
					tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, 'User *Not Found*', 1, 'md')
				end
			end

      tdcli_function ({
        ID = "SearchPublicChat",
        username_ = ap[2]
      }, setcontact, nil)

		end
					
		if cmd:match("^[/!#]setvip (%d+)$") and is_sudo(msg) then
			local ap = {string.match(cmd, "^([/!#]setcontact) (%d+)$")}
			function get_contact(extra, result, success)
			vardump(data)
				if result.id_ then
					if redis:sismember("vipusers", ap[2]) then
						tdcli.sendText(msg.chat_id_, 0, 0, 1, nil, "➿ User : "..ap[2].."\n*Already* Added To VIP Users", 1, 'md')
					
			 		else
						redis:sadd("vipusers", ap[2])
						tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "➿ User : "..ap[2].."\n*Added* to VIP users", 1, 'md')
					end
				else
						tdcli.sendText(msg.chat_id_, 0, 0, 1, nil, "User *Not Found*", 1, 'md')
				end
			end

			tdcli_function ({
				ID = "GetUser",
				user_id_ = ap[2]
			}, get_contact, nil)

		end


		if cmd:match("^[/!#]delvip (%d+)$") and is_sudo(msg) then
			local ap = {string.match(cmd, "^([/!#]delvip) (%d+)$")}
			function del_contact(extra, result, success)
			vardump(data)
				if result.id_ then
						if redis:sismember("vipusers", ap[2]) then
							redis:srem("vipusers", ap[2])
							tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "➿ User : "..ap[2].."\n*Deleted* From VIP users", 1, 'md')
         		else
							tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "➿ User : "..ap[2].."\n*Not Added* To VIP users", 1, 'md')
						end
					else
						tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, 'User *Not Found*', 1, 'md')
					end
				end


			tdcli_function ({
				ID = "GetUser",
				user_id_ = ap[2]
			}, del_contact, nil)

		end

			if cmd:match("^[/!#]stats") and is_sudo(msg) then
				local time = redis:hgetall("timer")
				local sec = time.secend
				local ho = time.hours
				local min = time.minute
				if redis:get("onlinemode") then
					on = "On"
				else
					on = "Off"
				end
				tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, '➰ Online Status Time :\n( '..ho..' ) Hours\n( '..min..' ) Minute\n( '..sec..' ) Secend\n➖➖➖➖➖➖\n➰ Online Mode : ( '..on..' )', 1, 'md')
			end
			if cmd:match("^[/!#]viplist")and  is_sudo(msg) then
				list = redis:smembers("vipusers")
				text = "VIP Users :\n\n"
				for k,v in pairs(list) do
						text = text..k.."-"..v.."\n"
				end
				if #list == 0 then
					text = "VIP Users is Empty"
				end
			tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, ''..text, 1, 'md')
			end

     	if cmd:match("^[/!#]help") and is_sudo(msg) then
        function inline(arg,data)
            tdcli_function({
              ID = "SendInlineQueryResultMessage",
              chat_id_ = msg.chat_id_,
              reply_to_message_id_ = msg.id_,
              disable_notification_ = 0,
              from_background_ = 1,
              query_id_ = data.inline_query_id_,
              result_id_ = data.results_[0].id_
            }, dl_cb, nil)
          end
				
        tdcli_function({
          ID = "GetInlineQueryResults",
          bot_user_id_ = 315070801,
          chat_id_ = msg.chat_id_,
          user_location_ = {
            ID = "Location",
            latitude_ = 0,
            longitude_ = 0
          },
          query_ = 'help',
          offset_ = 0
        }, inline, nil)
    end


  elseif (data.ID == "UpdateChat") then
    chat = data.chat_
    chats[chat.id_] = chat
  elseif (data.ID == "UpdateOption" and data.name_ == "my_id") then
    tdcli_function ({ID="GetChats", offset_order_="9223372036854775807", offset_chat_id_=0, limit_=20}, dl_cb, nil)
	end
end
end





