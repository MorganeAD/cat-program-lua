function love.load()
    love.graphics.setNewFont("font-bold.ttf", 20)

    socket = require "socket"
    address, port = "localhost", 12345

    udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername(address, port)

    t = 0
    updaterate = 0.2
    screen = 1
    user = {}

    messages = {}
    client_pseudo = ""
    text = ""
    ask_client = "What's your pseudo?"
end


function love.update(deltatime)
    t = t + deltatime
    if t > updaterate then
        if love.keyboard.isDown('backspace') then
            if string.len(text) > 0 then
                text = string.sub(text, 1, -2)
            end
            t=t-updaterate
        end
    end
    if screen == 1 then -- screen to ask user's client_pseudo
        if t > updaterate then
            if love.keyboard.isDown('return') then
                client_pseudo = text
                local dg = string.format("%s %s ", client_pseudo, 'loggin')
                udp:send(dg)
                text = ""
            end
            t=t-updaterate
        end

        repeat
        data, msg = udp:receive()
            if data then
                pseudo, message = data:match("^(%S*) (.*)$")
                if message == 'yes' then
                    screen = 2
                elseif message == 'no' then
                    ask_client = 'Pseudo already took, choose an other :'
                end
            end
        until not data
    end

    if screen == 2 then -- chat's screen
        -- the client send something to the server
        if t > updaterate then
            if love.keyboard.isDown('return') then
                local dg = string.format("%s %s %s", client_pseudo, 'says', text)
                udp:send(dg)
                text = ""
            end
            if love.keyboard.isDown('escape') then 
                local dg = string.format("%s %s ", client_pseudo, 'quit')
                udp:send(dg)
            end
            t=t-updaterate -- set t for the next round
        end

        -- if the server send something to the client
        repeat
            data, msg = udp:receive()
            if data then 
                pseudo, action, message = data:match("^(%S*) (%S*) (.*)$")
                if action == 'says' then
                    table.insert(messages, pseudo .. " : " .. message)
                -- elseif action == 'enters' then
                --     table.insert(users, pseudo)
                --     for k, v in pairs(users) do
                --         print(k, v)
                --     end
                --     print()
                elseif action == 'quit' then
                    love.event.quit()
                else
                    print("unrecognised command : ", data)
                end
            elseif msg ~= 'timeout' then
                error("Network error: "..tostring(msg))
            end
        until not data
    end

end

function love.draw()
    love.graphics.setBackgroundColor(52, 152, 219)
    if screen == 1 then
        love.graphics.setColor(236, 240, 241)
        love.graphics.rectangle("fill", 200, 150, 800-400, 600-300 )
        love.graphics.setColor(44, 62, 80)
        love.graphics.printf(ask_client, 0, 200, 800, 'center')
        love.graphics.printf(text, 0, 300, 800, 'center')
    end

    
    if screen == 2 then
        love.graphics.setColor(236, 240, 241)
        love.graphics.rectangle("fill", 20, 20, 800-160, 460 )
        love.graphics.rectangle("fill", 20, 500, 800-160, 80 )
        love.graphics.setColor(189, 195, 199)
        love.graphics.rectangle("fill", 680, 20, 100, 560 )
        love.graphics.setColor(44, 62, 80)
        love.graphics.printf(text, 30, 510, 800, 'left')
        for k, v in pairs(messages) do
            love.graphics.printf(v, 30, k*25, love.graphics.getWidth())
        end
    end
end

function love.textinput(t)
     text = text .. t
end