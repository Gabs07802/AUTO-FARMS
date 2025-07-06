-- DESATIVA O AUTO FARM IFOOD

_G.ifood_autofarm_ativo = false
if getgenv().noclipConn then pcall(function() getgenv().noclipConn:Disconnect() end) end
