-- 奥运会的时间
local tab = {year=2008, month=8, day=8, hour=20}
local pretime = os.time(tab)
print("08 Olympic Games time is "..pretime)

-- 现在的时间
local timetable = os.date("*t"); 
local nowtime = os.time(timetable)
print("now time is "..nowtime)

local difft = os.difftime(nowtime, pretime);

print("from 08 Olympic Games to now cost time "..difft.."s");