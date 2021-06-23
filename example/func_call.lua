function NewYinYinMonster ()
    local count = 'yin '
    return function () -- anonymous function
        count = count..count
        return count..'bo'
    end
end

C1 = NewYinYinMonster()
print(C1())
print(C1())

C2 = NewYinYinMonster()
print(C2())
print(C1())
print(C2())