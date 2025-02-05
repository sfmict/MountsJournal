local addon, ns = ...
local L, macroFrame = ns.L, ns.macroFrame
local _G, loadstring, setfenv, pcall = _G, loadstring, setfenv, pcall


local blockedFuncs = {
	getfenv = true,
	setfenv = true,
	loadstring = true,
	pcall = true,
	xpcall = true,
	SendMail = true,
	SetTradeMoney = true,
	AddTradeMoney = true,
	PickupTradeMoney = true,
	PickupPlayerMoney = true,
	TradeFrame = true,
	MailFrame = true,
	EnumerateFrames = true,
	RunScript = true,
	AcceptTrade = true,
	SetSendMailMoney = true,
	EditMacro = true,
	DevTools_DumpCommand = true,
	hash_SlashCmdList = true,
	RegisterNewSlashCommand = true,
	CreateMacro = true,
	SetBindingMacro = true,
	GuildDisband = true,
	GuildUninvite = true,
	securecall = true,
	DeleteCursorItem = true,
	ChatEdit_SendText = true,
	ChatEdit_ActivateChat = true,
	ChatEdit_ParseText = true,
	ChatEdit_OnEnterPressed = true,
	GetButtonMetatable = true,
	GetEditBoxMetatable = true,
	GetFontStringMetatable = true,
	GetFrameMetatable = true,
}
local blockedTables = {
	SlashCmdList = true,
	SendMailMailButton = true,
	SendMailMoneyGold = true,
	MailFrameTab2 = true,
	DEFAULT_CHAT_FRAME = true,
	ChatFrame1 = true,
	MountsJournalDB = true,
	MountsJournalChar = true,
}
local exec_env = setmetatable({}, {
	__index = function(t, k)
		if k == "_G" then
			return t
		elseif blockedFuncs[k] then
			return function() end
		elseif blockedTables[k] then
			return {}
		else
			return _G[k]
		end
	end,
	__metatable = false,
})
local cache = setmetatable({}, {__mode = "v"})


local function loadSnippet(str)
	if cache[str] then
		return cache[str]
	end

	local loadedFunc, err = loadstring("return function(state) "..str.."\nend")
	if err then
		return nil, err
	elseif loadedFunc then
		setfenv(loadedFunc, exec_env)
		local success, func = pcall(loadedFunc)
		if success then
			cache[str] = func
			return func
		end
	end
end


local function errHandler(id, err)
	print(addon, "'"..id.."'", "error.", "\nInstall the addons BugSack and BugGrabber for detailed error logs.")
	local message = ("%s %s: %s\n%s"):format(addon, L["Snippet"], id, err)
	geterrorhandler()(message)
end


do
	local snippetFunc = setmetatable({}, {
		__index = function(t, k)
			if macroFrame.snippets[k] then
				local func, err = loadSnippet(macroFrame.snippets[k])
				if err then
					print(addon, k, err)
				elseif func then
					t[k] = func
					return func
				end
			else
				print(addon, "Snippet '"..k.."' dosn't exist")
			end
			return function() end
		end
	})

	function macroFrame:callSnippet(id)
		local s1, s2 = pcall(snippetFunc[id], self.state)
		if s1 then return s2 end
		errHandler(id, s2)
	end

	function macroFrame:resetSnippet(id)
		snippetFunc[id] = nil
	end
end


macroFrame.loadSnippet = loadSnippet