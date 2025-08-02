local function makeClass(cls)
    cls._MT = {__index = cls}
    cls.new = function(...)
        local obj = setmetatable({}, cls._MT)
        obj:init(...)
        return obj
    end
end

local Trie = {
    init = function(self)
        self._value = nil
        self._next = {}
    end,
    put = function(self, key, value)
        self:putIter({ipairs(key)}, value)
    end,
    remove = function(self, key)
        self:removeIter({ipairs(key)})
    end,
    putIter = function(self, it, value)
        if value == nil then
            self:remove(it)
            return
        end
        local i, e = it[1](it[2], it[3])
        if i == nil then
            self._value = value
        else
            it[3] = i
            local child = self._next[e] or self.new()
            self._next[e] = child
            child:putIter(it, value)
        end
    end,
    removeIter = function(self, it)
        local i, e = it[1](it[2], it[3])
        if i == nil then
            self._value = nil
        else
            it[3] = i
            local child = self._next[e]
            if child ~= nil then
                self._next[e] = child:removeIter(it)
            end
        end
        if next(self._next) ~= nil or self._value ~= nil then
            return self
        else
            return nil
        end
    end,
    consumer = function(self)
        return self.Consumer.new(self)
    end,
    Consumer = {
        init = function(self, trie)
            self._trie = trie
            self._node = trie
            self._depth = 0
            self._lastValue = self._trie._value
            if self._lastValue == nil then
                self._lastFound = -1
            else
                self._lastFound = 0
            end
        end,
        hasNext = function(self)
            return next(self._node._next) ~= nil
        end,
        next = function(self, e)
            local child = self._node._next[e]
            if child == nil then
                return false
            end
            self._depth = self._depth + 1
            local value = child._value
            if value ~= nil then
                self._lastFound = self._depth
                self._lastValue = value
            end
            self._node = child
            return true
        end,
        getDeepest = function(self)
            return self._lastFound, self._lastValue
        end,
    }
}
makeClass(Trie)
makeClass(Trie.Consumer)

return Trie
