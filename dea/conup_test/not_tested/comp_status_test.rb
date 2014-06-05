# coding: UTF-8


require "../conup/comp_status"

if "NORMAL" == Dea::CompStatus::NORMAL
  puts "equal normal"
else
  puts "not equal normal"
end


if "ONDEMAND" == Dea::CompStatus::ONDEMAND
  puts "equal ondemand"
else
  puts "not equal normal"
end

if "VALID" == Dea::CompStatus::VALID
  puts "equal valid"
else
  puts "not equal normal"
end

if "FREE" == Dea::CompStatus::FREE
  puts "equal free"
else
  puts "not equal normal"
end

if "UPDATING" == Dea::CompStatus::UPDATING
  puts "equal updating"
else
  puts "not equal normal"
end