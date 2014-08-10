socket = require "socket"

udp = socket.udp()
udp:settimeout(0)
udp:setsockname('*', 12345)

users = {}
local data, msg_or_ip, port_or_nil
local pseudo, action, message

running = true

print "Server launch"
while running do
    data, msg_or_ip, port_or_nil = udp:receivefrom()
    if data then
        pseudo, action, message = data:match("^(%S*) (%S*) (.*)")
        if action == 'loggin' then
            if users[pseudo] then
                udp:sendto(string.format("%s %s", pseudo, 'no'), msg_or_ip,  port_or_nil)
            else
                users[pseudo] = {ip=msg_or_ip, port=port_or_nil}
                udp:sendto(string.format("%s %s", pseudo, 'yes'), msg_or_ip,  port_or_nil)
            end
        elseif action == 'says' then
            for k, v in pairs(users) do
                udp:sendto(string.format("%s %s %s", pseudo, 'says', message), v.ip,  v.port)
            end
        elseif action == 'quit' then            
            for k, v in pairs(users) do
                udp:sendto(string.format("%s %s ", k, 'quit'), msg_or_ip,  port_or_nil)
            end
            users[pseudo] = nil
        else
            print("unrecognised command:", action)
        end
    elseif msg_or_ip ~= 'timeout' then
        error("Unknown network error: "..tostring(msg))
    end
    socket.sleep(0.01)
end
