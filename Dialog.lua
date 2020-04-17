-- Requires loop.lua <https://github.com/a801-luadev/useful-stuff/blob/master/loop.lua>
-- Requires string.utf8.lua <https://github.com/a801-luadev/useful-stuff/blob/master/string.utf8.lua>

local dialog
do
	local cache = { }

	dialog = {
		_instances = {
			_count = 0
		}
	}

	-- Methods
	dialog.__index = dialog

	local emptyF = function() end
	dialog.begin = function(content, playerName)
		content = string.utf8(content)

		cache[content] = { }

		local obj = setmetatable({
			_content = content,
			_contentLen = #content,
			_playerName = playerName,
			_textPosition = 0,
			_running = false,
			_updateNumber = 1,
			_action = emptyF,
			_resetAction = nil
		}, dialog)

		dialog._instances._count = dialog._instances._count + 1
		dialog._instances[dialog._instances._count] = obj

		return obj
	end

	dialog.stop = function(self)
		self._running = false
		return self
	end

	dialog.resume = function(self)
		self._running = true
		return self
	end

	dialog.finish = function(self)
		self._textPosition = self._contentLen
		return self
	end

	dialog.reset = function(self)
		self._running = false
		self._textPosition = 0

		if self._resetAction then
			self._resetAction(self._playerName)
		end

		return self
	end

	dialog.isRunning = function(self)
		return self._running
	end

	dialog.setUpdateNumber = function(self, number)
		self._updateNumber = (number or 1)
		return self
	end

	dialog.setDisplayAction = function(self, f)
		if type(f) == "function" then
			self._action = f
		end
		return self
	end

	dialog.setResetAction = function(self, f)
		self._resetAction = f
		return self
	end

	-- Static methods
	local concat = table.concat
	local getContent = function(self)
		self._textPosition = self._textPosition + self._updateNumber
		local textPosition = self._textPosition

		if textPosition >= self._contentLen then
			textPosition = self._contentLen
			self:reset()
		end

		local c = cache[self._content]
		if not c[textPosition] then
			c[textPosition] = concat(self._content, nil, 1, textPosition, self._contentLen)
		end

		return c[textPosition]
	end

	local loopTimers
	local update = function()
		local instances = dialog._instances

		for obj = 1, instances._count do
			obj = instances[obj]

			if obj._running then
				obj._action(getContent(obj), obj._playerName)
			end
		end
	end

	dialog.setLoop = function(ticks)
		if loopTimers then
			for i = 1, #loopTimers do
				system.removeTimer(loopTimers[i])
			end
		end

		loopTimers = loop(update, (ticks or 12))
	end
end
