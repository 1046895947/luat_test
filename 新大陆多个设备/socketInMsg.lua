--- 模块功能：socket客户端数据接收处理
-- @author openLuat
-- @module socketLongConnectionTrasparent.socketInMsg
-- @license MIT
-- @copyright openLuat
-- @release 2018.03.28

module(..., package.seeall)
require "pins"
--- socket客户端数据接收处理
-- @param socketClient，socket客户端对象
-- @return 处理成功返回true，处理出错返回false
-- @usage socketInMsg.proc(socketClient)
function proc(socketClient)
	local result, data
	local Heart_Str = "$OK##\r"
	local Rec_Data
	local Rec_Status
	local Rec_Cmd
	local Rec_devices
	local key = pins.setup(pio.P0_6, 1)
	while true do
		result, data = socketClient:recv(2000)
		--接收到数据
		if result then
			log.info("socketInMsg.proc", data)
			if string.find(data, "$#AT") then
				sys.publish("UART_RECV_DATA", Heart_Str)
			end
			if string.find(data, "status") then
				Rec_Data = json.decode(data)
				Rec_Status = Rec_Data["status"]
				--log.info("Rec_Status",Rec_Status)  --控制台打印status值供调试
				if Rec_Status == 0 then
					sys.publish("SOCKET_RECV_DATA", "OK")
				end
			end
			if string.find(data, "data") then
				Rec_Data = json.decode(data)
				Rec_devices = Rec_Data["apitag"]
				Rec_Cmd = Rec_Data["data"]
				if "nl_lamp" == Rec_devices then
					if Rec_Cmd == 1 then
						sys.publish("SOCKET_RECV_DATA", "LEDON")
					else
						sys.publish("SOCKET_RECV_DATA", "LEDOFF")
					end
				end
				if "nl_fan" == Rec_devices then
					if Rec_Cmd == 1 then
						sys.publish("SOCKET_RECV_DATA", "FANON")
					else
						sys.publish("SOCKET_RECV_DATA", "FANOFF")
					end
				end
				if "nl_hot" == Rec_devices then
					if Rec_Cmd == 1 then
						sys.publish("SOCKET_RECV_DATA", "HOTON")
					else
						sys.publish("SOCKET_RECV_DATA", "HOTOFF")
					end
				end
			end
			--如果socketOutMsg中有等待发送的数据，则立即退出本循环
			if socketOutMsg.waitForSend() then
				return true
			end
		else
			break
		end
	end

	return result or data == "timeout"
end
