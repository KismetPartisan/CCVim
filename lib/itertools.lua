local function collectInto(result, ...)
    for k, v in ... do
        result[k] = v
    end
    return result
end

local function collect(...)
    return collectInto({}, ...)
end

local function listCopy(lst)
    return collect(ipairs(lst))
end

local function productNext(lstlst, oldIndices)
    local indices = listCopy(oldIndices)
    indices[#lstlst] = indices[#lstlst] + 1
    for i = #lstlst, 1, -1 do
        if indices[i] > #lstlst[i] then
            if i == 1 then
                return nil
            end
            indices[i - 1] = indices[i - 1] + 1
            indices[i] = 1
        else
            break
        end
    end
    local values = {}
    for i, lst in ipairs(lstlst) do
        values[i] = lst[indices[i]]
    end
    return indices, values
end

local function product(lstlst)
    local indices = {}
    for i = 1, #lstlst - 1 do
        indices[i] = 1
    end
    indices[#lstlst] = 0
    return productNext, lstlst, indices
end

local function update(dst, src)
    collectInto(dst, pairs(src))
end

local function enumerate(itNext, state, ...)
    local index = {...}
    local i = 0
    return function(...)
        i = i + 1
        index = {itNext(state, table.unpack(index))}
        if index[1] ~= nil then
            return i, table.unpack(index)
        end
        return nil
    end, state, index
end

return { product = product, collect = collect, update = update, enumerate = enumerate }
