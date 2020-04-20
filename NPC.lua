-- Requires loop.lua <https://github.com/a801-luadev/useful-stuff/blob/master/loop.lua>
-- Requires Callback.lua <https://github.com/a801-luadev/classes/blob/master/Callback.lua>

local npc
do
	local id = 199
	local nameHTML = "<p align='center'><font color='#%s' face='Verdana'><B>%s"
	local defaultNameColor = "FFF426"

	npc = {
		TICKS = 10,
		_instance = {
			_count = 0
		}
	}
	npc.__index = npc
	npc.__iter = function()
		return ipairs(npc._instance)
	end
	npc.__get = function(name)
		return npc._instance[npc._instance[name]]
	end

	npc.new = function(name, collection, layer)
		id = id + 1

		local self = setmetatable({
			id = id,

			x = 0,
			nameX = nil,
			y = 0,
			nameY = nil,
			w = 1,
			h = 1,

			_callback = nil,

			layer = layer,

			collection = collection,
			currentState = nil,
			_currentStateLen = 0,

			isStatic = false,
			looping = false
		}, npc)
		self:resetAction()

		if name then
			self:setName(name)
		end

		local instance = npc._instance
		instance._count = instance._count + 1
		instance[instance._count] = self
		instance[name] = instance._count

		return self
	end

	npc.resetAction = function(self)
		self:destroy(true)

		self.action = nil

		self.currentSpriteId = 0
		self.sprite = nil
	end

	npc.setPosition = function(self, x, y)
		self.x = x
		self.y = y

		return self
	end

	npc.setNamePosition = function(self, x, y)
		self.nameX = x
		self.nameY = y

		return self
	end

	npc.setDimension = function(self, w, h)
		self.w = w
		self.h = h

		return self
	end

	npc.setCollection = function(self, collection)
		self.collection = collection

		return self
	end

	npc.setLayer = function(self, layer)
		self.layer = layer

		return self
	end

	npc.setAction = function(self, action)
		self:resetAction()
		self.action = action

		return self
	end

	npc.setCallback = function(self, callbackName, callbackAction, borderRange)
		if self._callback then return self, false end

		self._callback = callback.new(callbackName, self.x, self.y, self.w, self.h):setClickable(borderRange)
		if callbackAction then
			self._callback:setAction(callbackAction)
		end

		return self, true
	end

	npc.setName = function(self, name, nameColor)
		self.rawname = name
		self._nameColor = color
		self._nameHTML = (name and string.format(nameHTML, (nameColor or defaultNameColor), name) or "")

		return self
	end

	npc.setNameColor = function(self, nameColor)
		if self.rawname then
			self._nameColor = color
			self._nameHTML = string.format(nameHTML, self._nameColor, name)
		end
		return self
	end

	npc.setState = function(self, state)
		if not self.collection then return self, false end

		state = self.collection[state]
		if not state then return self, false end

		self.currentState = state
		self._currentStateLen = #state

		return self, true
	end

	npc.setStatic = function(self)
		if not self.currentState then return self, false end

		self.action = nil
		self:display()

		return self, true
	end

	npc.deleteCallback = function(self, playerName)
		if not self._callback then return self, false end

		self._callback:remove(playerName)
		if not playerName then
			self._callback = nil
		end

		return self, true
	end

	npc.displayName = function(self)
		ui.addTextArea(self.id, self._nameHTML, nil, (self.nameX or self.x), (self.nameY or (self.y - 20)), 100, 20, 1, 1, 0, false)

		return self
	end

	npc.display = function(self, spriteIndex)
		if self.sprite then
			tfm.exec.removeImage(self.sprite)
		end
		self.sprite = tfm.exec.addImage(self.currentState[(spriteIndex or 1)], self.layer, self.x, self.y)

		if self.rawname then
			self:displayName()
		end

		return self
	end

	npc.destroy = function(self, keepCallback)
		self.looping = false

		if self.sprite then
			tfm.exec.removeImage(self.sprite)
		end

		if self.rawname then
			ui.removeTextArea(self.id)
		end

		if not keepCallback and self._callback then
			self._callback:remove()
		end
	end

	npc.loop = function(self)
		self.looping = true
		return self
	end

	npc._loop = function(self)
		if not self.looping then return end

		local spriteIndex = (self.currentSpriteId % self._currentStateLen) + 1
		spriteIndex = (self.action and self.action(self, spriteIndex)) or spriteIndex

		self.currentSpriteId = self.currentSpriteId + 1

		self:display(spriteIndex)
	end

	loop(function()
		for _, obj in npc.__iter() do
			obj:_loop()
		end
	end, npc.TICKS)
end

eventTextAreaCallback = function(id, playerName, eventName)
	if callback.eventTextAreaCallback(id, playerName, eventName) then return end
	
	-- TODO: eventTextAreaCallback
end
