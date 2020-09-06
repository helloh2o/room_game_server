module("pokers", package.seeall)

local ok   = "ok"
local err  = "err"
local none = "none"
local undefined = "undefined"

--------------------------------------------------------------------------------------

KINGS    = 5 -- 王
SPADES 	 = 4 -- 黑桃
HEARTS 	 = 3 -- 红桃
CLUBS  	 = 2 -- 梅花
DIAMONDS = 1 -- 方块

tile_type_desc = {
    [5] = '王',
    [4] = '♠️',
    [3] = '♥️',
    [2] = '♣️',
    [1] = '♦️',
}

--牌型
POKERS_TYPE_ERROR           = 0     --不合规的牌型
SINGLE_POKER				= 1     --单牌
PAIRS_POKERS                = 2     --对子
PROGRESSION_POKERS          = 3     --单顺子
PROGRESSION_PAIRS           = 4     --连对
THREE_WITH_ONE              = 5     --三带一
THREE_WITH_PAIRS            = 6     --三带一对
PROGRESSION_SUIT            = 7     --飞机
FOUR_WITH_TWO               = 8     --四代二
BOMB_POKERS                 = 9     --炸弹
THREE_WITH_NONE             = 10    --三不带


function co_get_cards_list(array)
    return coroutine.wrap(function()
        local all = array
        local all_length = #all

        local result_seq = {}

        local i, j, k, h, m = 0;

        for i=1, all_length do
            for j=i+1,all_length do
                for k=j+1, all_length do
                    for h=k+1, all_length do
                        for m=h+1, all_length do
                            local pai = { all[i], all[j], all[k], all[h], all[m] }

                            local type, index = tiles_to_pos_num(all[i])
                            local type1, index1 = tiles_to_pos_num(all[j])
                            local type2, index2 = tiles_to_pos_num(all[k])
                            local type3, index3 = tiles_to_pos_num(all[h])
                            local type4, index4 = tiles_to_pos_num(all[m])

                            local tt = {index, index1, index2, index3, index4}
                            table.sort(tt,
                            function (t1, t2)
                                if t1 < t2 then
                                    return true
                                else
                                    return false
                                end
                            end)

                            table.insert(result_seq, pai)
                            if #result_seq >= 100 then
                                table.sort(result_seq, function (t1, t2) return compare_seq(t1, t2) < 0 end)
                                coroutine.yield( result_seq )
                                result_seq = {}
                            end
                        end
                    end
                end
            end
        end

        if #result_seq > 0 then
            table.sort(result_seq, function (t1, t2) return compare_seq(t1, t2) < 0 end)
            coroutine.yield( result_seq )
        end
    end)
end

function get_b_max_seq(seqs)
    --get max seqs
    table.sort(seqs, function (t1, t2)
        local result = (compare_seq(t1, t2) > 0)
        if result then
            return true
        else
            return false
        end
    end)
    local max_seq = seqs[1]

    local all_poker = normal_shuffle_tiles()

    local send_seq = {} 
    for i, v in ipairs(seqs) do
        for i1, v1 in ipairs(v) do
            send_seq[v1] = 1 
        end
    end

    local remain_poker = {}
    for i, v in ipairs(all_poker) do
        if (not send_seq[v]) then
            table.insert(remain_poker, v)
        end
    end

    print("remain_poker:", #remain_poker)
    local cards_list_gen = co_get_cards_list(remain_poker)

    local co_count = 1
    while true do
        local cards_list = cards_list_gen()
        if not cards_list then break end

        print("cards_list_seq:", co_count)
        
        for i, v in ipairs(cards_list) do
            local result = compare_seq(v, max_seq)
            if result > 0 then
                return i, cards_list 
            end
        end

        if co_count >= 4 then
            break
        end

        co_count=co_count+1
    end

    return -1, nil 

    --from small to big old
    --local remain_rank_seq = get_rank_seq_reverse_lazy(remain_poker)

    --print("remain_rank_seq:", #remain_rank_seq)
    --
    --for i, v in ipairs(remain_rank_seq) do
    --    local result = compare_seq(v, max_seq)
    --    if result > 0 then
    --        return i, remain_rank_seq         
    --    end
    --end

    --if compare_seq(remain_rank_seq[#remain_rank_seq], max_seq) == 0 then
    --    return 0, remain_rank_seq
    --else
    --    return -1, remain_rank_seq
    --end
end


function check_da_shun(seq, teshu_rule)
    if (not teshu_rule) or (not teshu_rule.xiaoshuainiu) then
        return false
    end

    if (#seq ~= 5) then
        return false
    end

    local color = math.floor(seq[1] / 16)
    for i=2, #seq do
        if seq[i] - seq[i-1] ~= 1 then return false end
        if math.floor(seq[i] / 16) ~= color then return false end
    end

    return true
end

function check_hu_lu(result, teshu_rule)
    if (not teshu_rule) or (not teshu_rule.huluniu) then
        return false
    end

    local seq = result.seq
    if (#seq ~= 5) then
       return false
    end

    if result.points[1] == result.points[2] and
        result.points[2] == result.points[3] and
        result.points[4] == result.points[5] then
        return true
    end

    if result.points[1] == result.points[2] and
        result.points[3] == result.points[4] and
        result.points[4] == result.points[5] then
        return true
    end

	return false
end

function check_tong_hua(seq, teshu_rule)
    if (not teshu_rule) or (not teshu_rule.tonghuaniu) then
        return false
    end

    if (#seq ~= 5) then
        return false
    end

    table.sort(seq)

    return math.floor(seq[1] / 16) == math.floor(seq[5] / 16)
end

function check_shun_zi(result, teshu_rule)
    if (not teshu_rule) or (not teshu_rule.shunziniu) then
        return false
    end
    
    local seq_point = {}
    for i,v in ipairs(result.points) do table.insert(seq_point, v) end
    if (#seq_point ~= 5) then
        return false
    end

    table.sort(seq_point)

    for i=2, #seq_point do
        if seq_point[i] - seq_point[i-1] ~= 1 then return false end
    end

    return true
end

function check_wu_hua(result, teshu_rule)
    if (not teshu_rule) or (not teshu_rule.wuhuaniu) then
        return false
    end

    local seq = {}
    for i,v in ipairs(result.seq) do 
        if math.mod(v, 16) <= 10 then return false end
    end

    return true
end

function check_wu_xiao(result)
   local seq = result.seq

   if (#seq ~= 5) then
      return false
   end

   local all_value = 0
   
   for i, v in ipairs(result.points) do
        all_value = all_value + v
        if v >= 5 then
            return false
        end
   end

   if all_value >= 10 then
       return false
   end

   return true
end

--[[function check_wu_hua(result)
   local seq = result.seq
   if (#seq ~= 5) then
      return false
   end

   for i, v in ipairs(result.points) do
        if v > 0x0D or v < 0x0B then
            return false
        end
   end

   return true 
end]]

function check_zha_dan(result, teshu_rule)
    if (not teshu_rule) or (not teshu_rule.zhadanniu) then
        return false
    end

	local seq = result.seq
    if (#seq ~= 5) then
       return false
    end

    if result.points[1] == result.points[2] and
        result.points[2] == result.points[3] and
        result.points[3] == result.points[4] then
        return true
    end

    if result.points[2] == result.points[3] and
        result.points[3] == result.points[4] and
        result.points[4] == result.points[5] then
        return true
    end

	return false
end

function check_niuniu(result)
   local seq = result.seq
   if (#seq ~= 5) then
      return false
   end

   local p = result.numbers
   for i, v in ipairs(comb_5_3) do
       if math.mod(p[v[1]] + p[v[2]] + p[v[3]], 10) == 0 and
 		  math.mod(p[v[4]] + p[v[5]], 10) == 0 then
            result.final_seq = {seq[v[1]], 
                                seq[v[2]],
                                seq[v[3]],
                                seq[v[4]],
                                seq[v[5]]
            }
			return true
		end
   end

   return false 
end

function check_niu1_9(result)
   local seq = result.seq

	assert(#seq == 5)

   local p = result.numbers
   local level = 0
   for i, v in ipairs(comb_5_3) do
       if math.mod(p[v[1]] + p[v[2]] + p[v[3]], 10) == 0 then
			local lv = math.mod(p[v[4]] + p[v[5]], 10)
			--local lv = p[v[4]] + p[v[5]]
			if lv >= 1 and lv <= 9 then
				if lv >= level then
                    result.final_seq = {seq[v[1]], 
                    seq[v[2]],
                    seq[v[3]],
                    seq[v[4]],
                    seq[v[5]]
                }
					level = lv
				end
			end
		end
   end

	return level
end

function get_pretty_hand_seq(hand_seq)
    local temp = {}
    for i, v in ipairs(hand_seq) do
        table.insert(temp, v)
    end
    table.sort(temp, function(t1, t2)
        type1, id1 = tiles_to_pos_num(t1)
        type2, id2 = tiles_to_pos_num(t2)

        if (id1 < id2) then
            return true
        else
            return false
        end
    end)	

    return temp
end

function pretty_hand_seq(hand_seq)
    table.sort(hand_seq, function(t1, t2)
        type1, id1 = tiles_to_pos_num(t1)
        type2, id2 = tiles_to_pos_num(t2)

        if (id1 < id2) then
            return true
        else
            return false
        end
    end)	
end

function check_type(seq, room)
	assert(seq ~= nil)

    assert(#seq > 0)

	local result = {}

	--对seq从大到小排序
	--
    local temp_seq = {}
    local sort_seq = {}

	--cp seq
	for i, v in ipairs(seq) do
        table.insert(temp_seq, v)
        table.insert(sort_seq, v)
	end

    table.sort(temp_seq, function(t1, t2)
        local type1, id1 = tiles_to_pos_num(t1)
        local type2, id2 = tiles_to_pos_num(t2)

        if (id1 > id2) then
            return true
        else
            return false
        end
    end)	
    table.sort(sort_seq)
    result.seq = temp_seq 
    local has_kings = get_types_points(result)
    if has_kings then
        return check_type_with_kings(seq, room)
    end
	if check_da_shun(sort_seq, room.game_config.teshu_rule) then
		result.type = DA_SHUN 
	elseif check_zha_dan(result, room.game_config.teshu_rule) then
		result.type = ZHA_DAN 
	elseif check_hu_lu(result, room.game_config.teshu_rule) then
        result.type = HU_LU 
    elseif check_tong_hua(sort_seq, room.game_config.teshu_rule) then
        result.type = TONG_HUA 
    elseif check_wu_hua(result, room.game_config.teshu_rule) then
        result.type = WU_HUA 
    elseif check_shun_zi(result, room.game_config.teshu_rule) then
		result.type = SHUN_ZI 
	elseif check_niuniu(result) then
		result.type = NIU_NIU 
	else
		local level = check_niu1_9(result)
		result.type = WU_NIU + level
	end

    if result.final_seq == nil then
        result.final_seq = {}
        for i=#result.seq, 1, -1 do
            table.insert(result.final_seq, result.seq[i])
        end
    end

    do
        return result
    end

	--恢复seq
    if result.final_seq ~=  nil then
        result.seq = result.final_seq
    else
        pretty_hand_seq(result.seq)
    end

    --result.seq = seq
	--return result
end

--如果s1大于s2, return 1, == 0, <, return -1

function compare(result1, result2)
	if result1.type > result2.type then
			return 1
    elseif result1.type == result2.type then
        --葫芦牛和炸弹牛
        if (result1.type == HU_LU) or (result1.type == ZHA_DAN) then
            local point1 = (result1.points[1] == result1.points[3] and result1.points[1] or result1.points[5])
            local point2 = (result2.points[1] == result2.points[3] and result2.points[1] or result2.points[5])
            if point1 > point2 then 
                return 1
            elseif point1 < point2 then 
                return -1
            end
        end
		--先比点数
		local count = #result1.points
		for i=1, count do 
			if (result1.points[i] > result2.points[i]) then
				return 1
			elseif (result1.points[i] < result2.points[i]) then
				return -1
			else
			end
		end
		--再比花色
		--[[local count = #result1.types
		for i=1, count do 
			if (result1.types[i] > result2.types[i]) then
				return 1
			elseif (result1.types[i] < result2.types[i]) then
				return -1
			else
			end
        end]]
        
        local color1 = 0
        local color2 = 0
        for i = 1, #result1.seq do
            local type1, id1 = tiles_to_pos_num(result1.seq[i])
            local type2, id2 = tiles_to_pos_num(result2.seq[i])
            if id1 == result1.points[1] then
                if type1 > color1 then color1 = type1 end
            end
            if id2 == result2.points[1] then
                if type2 > color2 then color2 = type2 end
            end
        end

        return (color2 > color1 and -1 or 1)
	else
		return -1
	end	

end

function compare_seq(s1, s2)
   local result1 = check_type(s1)
   local result2 = check_type(s2)

   return compare(result1, result2)
end

function get_poker()
   local poker = {
      0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D,
      0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D,
      0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D,
      0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D,
      0x5E, 0x5F
   }
   return poker
end

function get_complete_poker()
    local poker = {
       0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D,
       0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D,
       0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D,
       0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4C, 0x4D,
       0x5E, 0x5F
    }
    return poker
 end

function deal_poker(poker)

   return table.remove(poker, 1)

end

function random_deal_poker(poker)
	local ran = math.random(#poker)

	local id = poker[ran]
	
	table.remove(poker, ran)

	return id
end

function tiles_to_pos_num(tile_id)
   local _type = math.floor(tile_id / 16)
   local _index = tile_id % 16

   return _type, _index
end

function get_desc_by_tile_id (tile_id)
	local type, id = tiles_to_pos_num(tile_id)
	local type_desc = tile_type_desc[type]
	local id_desc = tostring(id)
	if id == 11 then
		id_desc = 'J'
	elseif id == 12 then
		id_desc = 'Q'
	elseif id == 13 then
		id_desc = 'K'
	elseif id == 14 then
		id_desc = 'A'
	end

	return tostring(type_desc) .. id_desc
end

function normal_shuffle_tiles()
    local t = get_poker()
    
	return shuffled(t) 
end

function wanglai_shuffle_tiles()
    local t = get_complete_poker()
    
	return shuffled(t)   
end

function shuffled(tab)
    local temp_t = {}
    for i, v in ipairs(tab) do
        table.insert(temp_t, v)
    end

    local pokers = {}
    local count = #temp_t
    for i = 1, count do
        local index = math.random(1, count+1-i)
        table.insert(pokers, temp_t[index]) 
        temp_t[index] = temp_t[count+1-i]  
    end
	return pokers 
end

function remove_array(t, num)
    for i = 1, num do
        table.remove(t, 1)
    end
    return t
end

function remove_array_by_value(t, v, num)

    if num == nil then
        num = 1 
    end 

    --优化remove，如果num == 1, 从尾部先试验下
    if (num == 1) then
        if (v == t[#t]) then
            table.remove(t, #t)
            return 
        end
    end

    local acc = 0;
    
    local length = #t

    for i = 1, length do
        local index = length - i + 1
        if (t[index] == v) then

            acc = acc + 1

            table.remove(t, index)
            
            if (acc == num) then
                break
            end
        end
    end

end

function get_seq_type_beilv(seq_type1, seq_type2, game_config)
    if game_config.fan_bei == 1 then
        return fanbei_rule1[seq_type1] > fanbei_rule1[seq_type2] and fanbei_rule1[seq_type1] or fanbei_rule1[seq_type2]
    else
        return fanbei_rule2[seq_type1] > fanbei_rule2[seq_type2] and fanbei_rule2[seq_type1] or fanbei_rule2[seq_type2]
    end
end

function get_beilv_by_type(seq_type, game_config)
    return game_config.fan_bei == 1 and fanbei_rule1[seq_type] or fanbei_rule2[seq_type]
end

function check_type_with_kings(seq, room)
	local result = {type = WU_NIU, seq = {}, types = {}, points = {}, numbers = {}}
    --[[result.seq = {}
    result.types = {}
    result.points = {}
    result.numbers = {}]]
    --cp seq
    
    local temp_seq = {}
    local kings = {}
    for i, v in ipairs(seq) do
        if v < 0x5E then
            table.insert(temp_seq, v)
        else
            table.insert(kings, v)
        end
	end

    if #kings == 1 then
        check_type_with_one_king(temp_seq, result, room, kings)
    elseif #kings == 2 then
        check_type_with_two_kings(temp_seq, result, room, kings)
    end

    return result
end

function check_type_with_one_king(temp_seq, result, room, kings)
    local temp_type = nil
    local temp_card = nil
    local temp_final_seq = nil
    local sort_func = function(a, b) if a > b then return true else return false end end
    for i, v in ipairs(room.poker) do
        if v < 0x5E then
            local temp_t = {}
            local temp_s = {}
    
            for i1,v1 in ipairs(temp_seq) do 
                table.insert(temp_t, v1) 
                table.insert(temp_s, v1)
            end

            table.insert(temp_t, v)
            table.sort(temp_t, function(t1, t2)
                local type1, id1 = tiles_to_pos_num(t1)
                local type2, id2 = tiles_to_pos_num(t2)
        
                if (id1 > id2) then
                    return true
                else
                    return false
                end
            end)

            table.insert(temp_s, v)
            table.sort(temp_s)

            result.seq = temp_t

            for i1, v1 in ipairs(result.seq) do
                local type1, id1 = tiles_to_pos_num(v1)
                table.insert(result.types, type1)
                table.insert(result.points, id1)
                
                if id1 > 10 then
                    table.insert(result.numbers, 10)
                else
                    table.insert(result.numbers, id1)
                end
            end

	        table.sort(result.types, sort_func)
	        table.sort(result.points, sort_func)
            table.sort(result.numbers, sort_func)
    
	        if check_da_shun(temp_s, room.game_config.teshu_rule) then
		        result.type = DA_SHUN 
	        elseif check_zha_dan(result, room.game_config.teshu_rule) then
		        result.type = ZHA_DAN 
	        elseif check_hu_lu(result, room.game_config.teshu_rule) then
                result.type = HU_LU 
            elseif check_tong_hua(temp_s, room.game_config.teshu_rule) then
                result.type = TONG_HUA 
            elseif check_wu_hua(result, room.game_config.teshu_rule) then
                result.type = WU_HUA 
            elseif check_shun_zi(result, room.game_config.teshu_rule) then
		        result.type = SHUN_ZI 
	        elseif check_niuniu(result) then
		        result.type = NIU_NIU 
	        else
		        local level = check_niu1_9(result)
		        result.type = WU_NIU + level
            end

            if temp_type == nil then
                temp_type = result.type
                temp_card = v
            else
                local bigger = false
                if result.type > temp_type then
                    bigger = true
                elseif result.type == temp_type then
                    local type1, id1 = tiles_to_pos_num(v)
                    local type2, id2 = tiles_to_pos_num(temp_card)
                    if id1 >id2 then
                        bigger = true
                    elseif id1 == id2 then
                        if type1 > type2 then
                            bigger = true
                        end
                    end
                end

                if bigger then
                    temp_type = result.type
                    temp_card = v
                    temp_final_seq = {}

                    if result.final_seq then
                        for i3, v3 in ipairs(result.final_seq) do 
                            table.insert(temp_final_seq, v3) 
                        end
                    else
                        temp_final_seq = nil
                    end
                end
            end
            result.type = WU_NIU
            result.seq = {}
            result.types = {}
            result.points = {}
            result.numbers = {}
            result.final_seq = nil
        end
    end

    assert(temp_type and temp_card)
    result.type = temp_type
    table.insert(temp_seq, temp_card)
    table.sort(temp_seq, function(t1, t2)
        local type1, id1 = tiles_to_pos_num(t1)
        local type2, id2 = tiles_to_pos_num(t2)

        if (id1 > id2) then
            return true
        else
            return false
        end
    end)

    result.seq = temp_seq
    result.final_seq = temp_final_seq

    if result.final_seq == nil then
        result.final_seq = {}
        for i=#result.seq, 1, -1 do
            table.insert(result.final_seq, result.seq[i])
        end
    end

    for i, v in ipairs(result.final_seq) do
        if v == temp_card then
            result.final_seq[i] = kings[1]
             break
         end
    end

    for i1, v1 in ipairs(result.seq) do
        local type1, id1 = tiles_to_pos_num(v1)
        table.insert(result.types, type1)
        table.insert(result.points, id1)
                
        if id1 > 10 then
            table.insert(result.numbers, 10)
        else
            table.insert(result.numbers, id1)
        end
    end

    table.sort(result.types, sort_func)
	table.sort(result.points, sort_func)
    table.sort(result.numbers, sort_func)
end

function check_type_with_two_kings(temp_seq, result, room, kings)
    local temp_type = nil
    local temp_card = nil
    local temp_final_seq = nil
    local sort_func = function(a, b) if a > b then return true else return false end end
    for i, v in ipairs(room.poker) do
        for ii, vv in ipairs(room.poker) do
            if v ~= vv then
                local temp_t = {}
                local temp_s = {}
    
                for i1,v1 in ipairs(temp_seq) do 
                    table.insert(temp_t, v1) 
                    table.insert(temp_s, v1)
                end

                table.insert(temp_t, v)
                table.insert(temp_t, vv)
                table.sort(temp_t, function(t1, t2)
                    local type1, id1 = tiles_to_pos_num(t1)
                    local type2, id2 = tiles_to_pos_num(t2)
        
                    if (id1 > id2) then
                        return true
                    else
                        return false
                    end
                end)

                table.insert(temp_s, v)
                table.insert(temp_s, vv)
                table.sort(temp_s)

                result.seq = temp_t

                for i1, v1 in ipairs(result.seq) do
                    local type1, id1 = tiles_to_pos_num(v1)
                    table.insert(result.types, type1)
                    table.insert(result.points, id1)
                
                    if id1 > 10 then
                        table.insert(result.numbers, 10)
                    else
                        table.insert(result.numbers, id1)
                    end
                end

	            table.sort(result.types, sort_func)
	            table.sort(result.points, sort_func)
                table.sort(result.numbers, sort_func)
    
	            if check_da_shun(temp_s, room.game_config.teshu_rule) then
		            result.type = DA_SHUN 
	            elseif check_zha_dan(result, room.game_config.teshu_rule) then
		            result.type = ZHA_DAN 
	            elseif check_hu_lu(result, room.game_config.teshu_rule) then
                    result.type = HU_LU 
                elseif check_tong_hua(temp_s, room.game_config.teshu_rule) then
                    result.type = TONG_HUA 
                elseif check_wu_hua(result, room.game_config.teshu_rule) then
                    result.type = WU_HUA 
                elseif check_shun_zi(result, room.game_config.teshu_rule) then
		            result.type = SHUN_ZI 
	            elseif check_niuniu(result) then
		            result.type = NIU_NIU 
	            else
		            local level = check_niu1_9(result)
		            result.type = WU_NIU + level
                end

                if temp_type == nil then
                    temp_type = result.type
                    temp_card = {v, vv}
                else
                    local bigger = false
                    if result.type > temp_type then
                        bigger = true
                    elseif result.type == temp_type then
                        local tm = compare_two_cards({v, vv}, temp_card)
                        if tm == 1 then
                            bigger = true
                        end
                    end

                    if bigger then
                        temp_type = result.type
                        temp_card = {v, vv}
                        temp_final_seq = {}

                        if result.final_seq then
                            for i3, v3 in ipairs(result.final_seq) do 
                                table.insert(temp_final_seq, v3) 
                            end
                        else
                            temp_final_seq = nil
                        end
                    end
                end
                result.type = WU_NIU
                result.seq = {}
                result.types = {}
                result.points = {}
                result.numbers = {}
                result.final_seq = nil
            end
        end
    end

    assert(temp_type and (#temp_card==2))
    result.type = temp_type
    table.insert(temp_seq, temp_card[1])
    table.insert(temp_seq, temp_card[2])
    table.sort(temp_seq, function(t1, t2)
        local type1, id1 = tiles_to_pos_num(t1)
        local type2, id2 = tiles_to_pos_num(t2)

        if (id1 > id2) then
            return true
        else
            return false
        end
    end)

    result.seq = temp_seq
    result.final_seq = temp_final_seq

    if result.final_seq == nil then
        result.final_seq = {}
        for i=#result.seq, 1, -1 do
            table.insert(result.final_seq, result.seq[i])
        end
    end

    for i, v in ipairs(result.final_seq) do
        if v == temp_card[1] then
            result.final_seq[i] = kings[1]
        elseif v == temp_card[2] then
            result.final_seq[i] = kings[2]
        end
    end

    for i1, v1 in ipairs(result.seq) do
        local type1, id1 = tiles_to_pos_num(v1)
        table.insert(result.types, type1)
        table.insert(result.points, id1)
                
        if id1 > 10 then
            table.insert(result.numbers, 10)
        else
            table.insert(result.numbers, id1)
        end
    end

    table.sort(result.types, sort_func)
	table.sort(result.points, sort_func)
    table.sort(result.numbers, sort_func)
end

function compare_two_cards(s1, s2)
    local sort_func = function(a, b) if a > b then return true else return false end end
    assert(#s1 > 0 and #s1 == #s2)
    
    local colors1 = {}
    local points1 = {}

    local colors2 = {}
    local points2 = {}

    for i = 1, #s1 do
        local type1, id1 = tiles_to_pos_num(s1[i])
        local type2, id2 = tiles_to_pos_num(s2[i])

        table.insert(colors1, type1)
        table.insert(points1, id1)

        table.insert(colors2, type2)
        table.insert(points2, id2)
    end

    table.sort(colors1, sort_func)
    table.sort(points1, sort_func)
    table.sort(colors2, sort_func)
    table.sort(points2, sort_func)
    
    for i = 1, #points2 do
        if points1[i] > points2[i] then
            return 1
        elseif points1[i] < points2[i] then
            return 2
        else
        end
    end

    for i = 1, #colors1 do
        if colors1[i] > colors2[i] then
            return 1
        elseif colors1[i] < colors2[i] then
            return 2
        else
        end
    end
 
    return 0
end

function chu_tile(tile_id, room, seat)   
    local chu_success = false
    for i, v in ipairs(seat.hand_seq) do
        if (v == tile_id) then
            table.insert(room.old_seqs, v)
            table.insert(seat.chued_seq, v)

            table.remove(seat.hand_seq, i)
            table.sort(seat.hand_seq)

            chu_success = true
            break
         end
    end

    return chu_success
end

function pokers_type_check(pokers)
    assert(pokers ~= nil and #pokers > 0)
    table.sort(pokers)
    if (#pokers == 1) then
        return SINGLE_POKER, get_poker_point(pokers[1])
    end

    local pokers_point = {}
    for i, v in ipairs(pokers) do
        table.insert(pokers_point, get_poker_point(v))
    end
    table.sort(pokers_point)

    if (#pokers == 2) then  --[王炸]或者[对子]
        if (pokers[1] == 0x5E and pokers[2] == 0x5F) then
            return BOMB_POKERS, pokers_point[1]
        else
            --return (pokers_point[1] == pokers_point[2]) and PAIRS_POKERS or POKERS_TYPE_ERROR
            if pokers_point[1] == pokers_point[2] then
                return PAIRS_POKERS, pokers_point[1]
            else
                return POKERS_TYPE_ERROR, 0
            end
        end
    elseif (#pokers == 3) then  --只能是[三不带]
        if pokers_point[1] == pokers_point[3] then 
            return THREE_WITH_NONE, pokers_point[1]
        end
    elseif (#pokers == 4) then  --[炸弹]或者[三带一]       
        if pokers_point[1] == pokers_point[4] then
            return BOMB_POKERS, pokers_point[1]
        end

        if pokers_point[1] == pokers_point[3] then
            return THREE_WITH_ONE, pokers_point[1]
        elseif pokers_point[2] == pokers_point[4] then
            return THREE_WITH_ONE, pokers_point[2]
        end

        return POKERS_TYPE_ERROR, 0
    else    --[顺子],[飞机],[连对],[四代二],[三带一对],不能两个王同时出现
        if (pokers[#pokers] == 0x5F and pokers[#pokers-1] == 0x5E) then return POKERS_TYPE_ERROR, 0 end
        if (pokers_point[#pokers_point] < 0x0F) then   --顺子和连对中不能有2和王
            if is_progression_pokers(pokers_point) then
                return PROGRESSION_POKERS, pokers_point[1]
            elseif is_progression_pairs(pokers_point) then
                return PROGRESSION_PAIRS, pokers_point[1]
            end
        end
 
        if is_three_with_pairs(pokers_point) then return THREE_WITH_PAIRS, pokers_point[3] end

        local poker_point = is_four_with_two(pokers_point)
        if poker_point > 0 then return FOUR_WITH_TWO, poker_point end

        poker_point = is_progression_suit(pokers_point)
        if poker_point > 0 then return PROGRESSION_SUIT, poker_point end
    end

    return POKERS_TYPE_ERROR, 0
end

--单顺子判断
function is_progression_pokers(pokers_point)
    for i = 1, #pokers_point-1 do
        if (pokers_point[i+1] ~= pokers_point[i]+1) then
            return false
        end
    end

    return true
end

--连对判断
function is_progression_pairs(pokers_point)
    if (#pokers_point % 2 ~= 0) then return false end

    local point = {}
    for i = 1, #pokers_point / 2 do
        if (pokers_point[i*2] ~= pokers_point[i*2-1]) then
            return false
        end
        table.insert(point, pokers_point[i*2])
    end

    return is_progression_pokers(point)
end

--三带一对
function is_three_with_pairs(pokers_point)
    if (#pokers_point ~= 5) or (pokers_point[5] > 0x0F) then return false end

    if ((pokers_point[1] == pokers_point[3]) and (pokers_point[4] == pokers_point[5])) or 
        ((pokers_point[1] == pokers_point[2]) and (pokers_point[3] == pokers_point[5])) then
        return true
    end

    return false
end

--四代二判断
function is_four_with_two(pokers_point)
    if (#pokers_point == 6) then    --带两张单牌    AAAABC/ABBBBC/ABCCCC
        if (pokers_point[1] == pokers_point[4]) or (pokers_point[2] == pokers_point[5]) or (pokers_point[3] == pokers_point[6]) then
            return pokers_point[3]
        end
    elseif (#pokers_point == 8) then    --带两对    AAAABBCC/AABBBBCC/AABBCCCC
        if ((pokers_point[1] == pokers_point[4]) and (pokers_point[5] == pokers_point[6]) and (pokers_point[7] == pokers_point[8])) then
            return pokers_point[1]
        elseif ((pokers_point[3] == pokers_point[6]) and (pokers_point[1] == pokers_point[2]) and (pokers_point[7] == pokers_point[8])) then
            return pokers_point[3]
        elseif ((pokers_point[5] == pokers_point[8]) and (pokers_point[1] == pokers_point[2]) and (pokers_point[3] == pokers_point[4])) then
            return pokers_point[5]
        end
    end

    return 0
end

--飞机判断
function is_progression_suit(pokers_point)
    local sigle_card = {}
    local pairs_card = {}
    local three_card = {}

    local point = poker_point[1]
    local index = 1
    for i, v in ipairs(poker_point) do
        if point ~= v then
            if (i - index == 1) then
                table.insert(sigle_card, point)
            elseif (i - index == 2) then
                table.insert(pairs_card, point)
            elseif (i - index == 3) then
                table.insert(three_card, point)
            elseif (i - index == 4) then
                return 0
            end
            point = v
            index = i
        end
    end

    if index == #poker_point then
        table.insert(sigle_card, poker_point[#poker_point])
    elseif index == #poker_point-1 then
        table.insert(pairs_card, poker_point[#poker_point])
    elseif index == #poker_point-2 then
        table.insert(three_card, poker_point[#poker_point])
    elseif index == #poker_point-3 then
        return 0
    end

    if #three_card == 0 or is_progression_pokers(three_card) == false then return 0 end
    if (#sigle_card > 0 and #pairs_card > 0) then return 0 end
    
    if (#three_card == #sigle_card or #three_card == #pairs_card) then
        return three_card[1]
    end

    return 0
end

function get_poker_point(poker)
    local point = poker % 0x10
    -- A的点数是E
    -- 2的点数是F
    -- 小王(0x5E)的点数是0x10
    -- 大王(0x5F)的点数是0x11
    --return point == 1 and 0x0E or point
    if (point < 3) then
        return 0x0D + point
    elseif (point > 0x0D) then
        return point + 2
    else
        return point
    end
end

function get_poker_color(poker)
    return math.floor(poker / 0x10)
end

function notify_other_hand_seq(room, seat_index, pokers_count)
    local temp_pokers = {}
    for i=1, pokers_count do
        table.insert(temp_pokers, 0)
    end

    local other_pokers = {}
    for i, v in ipairs(room.seats) do
        if i ~= seat_index then
            table.insert(other_pokers, {
                seat_index = i,
                hand_seq = {
                    pokers = temp_pokers,
                    count = #temp_pokers
                }
            })
        end
    end
end
