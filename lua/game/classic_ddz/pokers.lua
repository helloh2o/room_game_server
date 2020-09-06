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
PROGRESSION_SUIT_NONE       = 7     --飞机(不带)
FOUR_WITH_TWO               = 8     --四代二
BOMB_POKERS                 = 9     --炸弹
THREE_WITH_NONE             = 10    --三不带
PROGRESSION_SUIT_ONE        = 11     --飞机(带单)
PROGRESSION_SUIT_TWO        = 11     --飞机(带对)


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

function pokers_type_check(pokers, banker_type, banker_pokers_count)
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
        if banker_pokers_count > 0 and banker_pokers_count ~= #pokers then return POKERS_TYPE_ERROR, 0 end
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

        if banker_type == PROGRESSION_SUIT_ONE or banker_type == PROGRESSION_SUIT_TWO or banker_type == PROGRESSION_SUIT_NONE then
            poker_type, poker_point = is_progression_suit(pokers_point, banker_type)
            if poker_type > 0 and poker_point > 0 then return poker_type, poker_point end
        end
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
    if (#pokers_point % 2 ~= 0) or #pokers_point < 6 then return false end

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
function is_progression_suit(pokers_point, banker_type)
    local sigle_card = {}
    local pairs_card = {}
    local three_cards = {}

    local point = pokers_point[1]
    local index = 1
    for i, v in ipairs(pokers_point) do
        if point ~= v then
            if (i - index == 1) then
                table.insert(sigle_card, point)
            elseif (i - index == 2) then
                table.insert(pairs_card, point)
            elseif (i - index == 3) then
                table.insert(three_cards, point)
            elseif (i - index == 4) then
                return 0, 0
            end
            point = v
            index = i
        end
    end

    if index == #pokers_point then
        table.insert(sigle_card, pokers_point[#pokers_point])
    elseif index == #pokers_point-1 then
        table.insert(pairs_card, pokers_point[#pokers_point])
    elseif index == #pokers_point-2 then
        table.insert(three_cards, pokers_point[#pokers_point])
    elseif index == #pokers_point-3 then
        return 0, 0
    end

    --if #three_cards == 0 or is_progression_pokers(three_cards) == false then return 0, 0 end
    if #three_cards < 2 then return 0, 0 end

    if banker_type == PROGRESSION_SUIT_ONE then
        if #sigle_card + #pairs_card * 2 < #three_cards then
            if #three_cards < 4 then return 0, 0 end
            local case1 = {}
            local case2 = {}
            for i = 2, #three_cards do table.insert(case1, three_cards[i]) end
            for i = 1, #three_cards-1 do table.insert(case2, three_cards[i]) end

            local case1_ret = is_progression_pokers(case1)
            local case2_ret = is_progression_pokers(case2)
            if case1_ret or case1_ret2 then
                if #three_cards-1 == (#sigle_card + #pairs_card * 2 + 3) then
                    local point = case1_ret and three_cards[2] or three_cards[1]
                    return PROGRESSION_SUIT_ONE, point
                end
            end
        else
            if is_progression_pokers(three_cards) == false then return 0, 0 end
            if #three_cards == (#sigle_card + #pairs_card * 2) then
                return PROGRESSION_SUIT_ONE, three_cards[1]
            end
        end
    elseif banker_type == PROGRESSION_SUIT_TWO then
        if is_progression_pokers(three_cards) == false then return 0, 0 end
        if #three_cards == #pairs_card and #sigle_card == 0 then
            return PROGRESSION_SUIT_TWO, three_cards[1]
        end
    elseif banker_type == PROGRESSION_SUIT_NONE then
        if is_progression_pokers(three_cards) == false then return 0, 0 end
        if #sigle_card == 0 and #pairs_card == 0 then
            return PROGRESSION_SUIT_NONE, three_cards[1]
        end
    end

    return 0, 0
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
    local other_pokers = {}
    for i, v in ipairs(room.seats) do
        if i ~= seat_index then
            table.insert(other_pokers, {
                seat_index = i,
                mingpai = v.mingpai > 0 and 1 or 0,
                hand_seq = {
                    pokers = v.mingpai > 0 and v.hand_seq or nil,
                    count = pokers_count
                }
            })
        end
    end

    return other_pokers
end

function get_dizhu_pokers_beishu(room)
    local pokers_point = {}
    local pokers_color = {}
    local pokers = {}
    for i, v in ipairs(room.dizhu_pokers) do
        table.insert(pokers_point, get_poker_point(v))
        table.insert(pokers_color, get_poker_color(v))
        table.insert(pokers, v)
    end
    table.sort(pokers_point)
    table.sort(pokers)
    if pokers[3] == 0x5F and pokers[2] == 0x5E then --双王3倍
        return 3
    end

    if pokers[3] >= 0x5E then --单王2倍
        return 2
    end

    if pokers_point[1] == pokers_point[3] then --三连4倍
        return 4
    end 

    if pokers_color[1] == pokers_color[2] and pokers_color[1] == pokers_color[3] then --同花3倍
        return 3
    end

    if pokers_point[1]+1 == pokers_point[2] and pokers_point[2]+1 == pokers_point[3] and pokers_point[3] < 0x0F then --顺子3倍
        return 3
    end

    return 1
end

--取一个最小点数的牌
function get_default_poker(room)
    table.sort(room.seats[room.curr_turn].hand_seq)
    local point = 0
    local poker = 0
    for i, v in ipairs(room.seats[room.curr_turn].hand_seq) do
        local v_point = get_poker_point(v)
        if point == 0 or point > v_point then 
            point = v_point 
            poker = v
        end
        if point == 3 then break end
    end

    return poker
end

function remove_hand_seq_pokers(seat, pokers)
    local hand_seq = seat.hand_seq
    for i1, v1 in ipairs(pokers) do
        local remove_sure = false
        for i2, v2 in ipairs(hand_seq) do
            if (v1 == v2) then 
                remove_sure = true
                table.remove(hand_seq, i2) 
                break
            end
        end

        if remove_sure == false then
            return false
        end
    end

    return true
end

function get_auto_action_pokers(room)
    local hand_seq = room.seats[room.curr_turn].hand_seq
    table.sort(hand_seq)

    if #hand_seq == 2 and hand_seq[1] == 0x5E and hand_seq[2] == 0x5F then
        return hand_seq
    end

    local cards = {
        [3] = {},
        [4] = {},
        [5] = {},
        [6] = {},
        [7] = {},
        [8] = {},
        [9] = {},
        [10] = {},
        [11] = {},
        [12] = {},
        [13] = {},
        [14] = {},
        [15] = {},
        [16] = {},
        [17] = {}
    }
    local index = 1
    for i, v in ipairs(hand_seq) do
        local point = get_poker_point(v)
        --cards[point] = cards[point] + 1
        table.insert(cards[point], v)
    end

    local type, point = pokers_type_check(hand_seq, 0, 0)

    local ret = {}
    if room.curr_turn == room.banker_seat or room.banker_seat == 0 then  --这轮第一个出牌
        if type ~= 0 then return hand_seq end
        ret = get_auto_action_pokers_chupai(cards)
    else --接牌
        local banker_type = room.seats[room.banker_seat].last_chu.pokers_type
        local banker_point = room.seats[room.banker_seat].last_chu.pokers_point
        if type ~= 0 then
            if type == BOMB_POKERS and banker_type ~= BOMB_POKERS then
                return hand_seq 
            end

            if banker_type == type and point > banker_point and (#hand_seq == #room.seats[room.banker_seat].last_chu.pokers or type == BOMB_POKERS) then
                return hand_seq 
            end
        end
        ret = get_auto_action_pokers_jiepai(room, cards)
    end

    return ret
end

function get_auto_action_pokers_chupai(cards)
    local ret = 0
    for i=3, 17 do
        if #cards[i] > 0 then 
            ret = i
            break
        end 
    end

    return cards[ret]
end

function get_auto_action_pokers_jiepai(room, cards)
    local hand_seq = room.seats[room.curr_turn].hand_seq
    local banker_type = room.seats[room.banker_seat].last_chu.pokers_type
    local banker_point = room.seats[room.banker_seat].last_chu.pokers_point
    local banker_pokers = room.seats[room.banker_seat].last_chu.pokers
    if banker_type == SINGLE_POKER then
        return find_sigle_card(cards, banker_point)
    elseif banker_type == PAIRS_POKERS then
        return find_pairs_card(cards, banker_point)
    elseif banker_type == PROGRESSION_POKERS then
        return find_progression_cards(cards, banker_point, banker_pokers)
    elseif banker_type == PROGRESSION_PAIRS then
        return find_progression_pairs(cards, banker_point, banker_pokers)
    elseif banker_type == THREE_WITH_ONE then
        return find_three_with_one(cards, banker_point)
    elseif banker_type == THREE_WITH_PAIRS then
        return find_three_with_pairs(cards, banker_point)
    elseif banker_type == PROGRESSION_SUIT_NONE then
        return find_progression_suit_none()
    elseif banker_type == PROGRESSION_SUIT_ONE then
        return find_progression_suit_one()
    elseif banker_type == PROGRESSION_SUIT_TWO then
        return find_progression_suit_two()
    elseif banker_type == FOUR_WITH_TWO then
        return find_four_with_two(cards, banker_point, banker_pokers)
    elseif banker_type == BOMB_POKERS then
        return find_boom(cards, banker_point)
    elseif banker_type == THREE_WITH_NONE then
        return find_three_with_none(cards, banker_point)
    end
end

function find_sigle_card(cards, banker_point)
    local ret = {{}, {}, {}, {}}
    for i = 3, 17 do
        if #cards[i] == 1 and i > banker_point then
            return cards[i]
        end

        if #cards[i] == 2 and i > banker_point and #ret[2] == 0 then
            ret[2] = {cards[i][1]}
        end

        if #cards[i] == 3 and i > banker_point and #ret[3] == 0 then
            ret[3] = {cards[i][1]}
        end

        if #cards[i] == 4 and #ret[4] == 0 then
            ret[4] = cards[i]
        end
    end

    for i, v in ipairs(ret) do
        if #v > 0 then 
            return v 
        end
    end

    local return_ret = {}
    return return_ret 
end

function find_pairs_card(cards, banker_point)
    local ret = {{}, {}, {}, {}}
    for i = 3, 17 do
        if #cards[i] == 2 and i > banker_point then
            return cards[i]
        end

        if #cards[i] == 3 and i > banker_point and #ret[3] == 0 then
            ret[3] = {cards[i][1], cards[i][2]}
        end

        if #cards[i] == 4 and #ret[4] == 0 then
            ret[4] = cards[i]
        end
    end

    for i, v in ipairs(ret) do
        if #v > 0 then 
            return v 
        end
    end

    local return_ret = {}
    if #cards[16] == 1 and #cards[17] == 1 then return_ret = {0x5E, 0x5F} end
    return return_ret 
end

function find_three_with_one(cards, banker_point)
    local ret = {{}, {}, {}, {}}
    local little_cards = {}
    for i = 3, 15 do
        if #cards[i] == 1 and #ret[1] == 0 then
            ret[1] = cards[i]
        end

        if #cards[i] == 2 and #ret[2] == 0 then
            ret[2] = cards[i]
        end

        if #cards[i] == 3 then
            if i > banker_point then
                table.insert(ret[3], cards[i])
            else
                table.insert(little_cards, cards[i])
            end
        end

        if #cards[i] == 4 and #ret[4] == 0 then
            ret[4] = cards[i]
        end
    end

    if #ret[4] == 0 and #cards[16] == 1 and #cards[17] == 1 then
        ret[4] = {0x5E, 0x5F}
    end

    if #ret[3] == 0 and #ret[4] > 0 then
        return ret[4]
    end

    local return_ret = {}
    if #ret[3] > 0 then
        table.insert(return_ret, ret[3][1][1])
        table.insert(return_ret, ret[3][1][2])
        table.insert(return_ret, ret[3][1][3])
        if #ret[1] > 0 then
            table.insert(return_ret, ret[1][1])
        elseif #ret[2] > 0 then
            table.insert(return_ret, ret[2][1])
        elseif #little_cards > 0 then
            table.insert(return_ret, little_cards[1][1])
        elseif #ret[3] > 1 then
            table.remove(return_ret, 3)
            table.remove(return_ret, 2)
            table.insert(return_ret, ret[3][2][1])
            table.insert(return_ret, ret[3][2][2])
            table.insert(return_ret, ret[3][2][3])
        end
    end

    if #return_ret < 4 then
        if #return_ret == 3 then
            if #cards[16] == 1 and #cards[17] == 0 then
                table.insert(return_ret, cards[16][1])
                return return_ret
            elseif #cards[17] == 1 and #cards[16] == 0 then
                table.insert(return_ret, cards[17][1])
                return return_ret
            end
        end
        return ret[4]
    else
        return return_ret
    end
end

function find_three_with_pairs(cards, banker_point)
    local ret = {{}, {}, {}, {}}
    local little_cards = {}
    for i = 3, 17 do
        if #cards[i] == 2 and #ret[2] == 0 then
            ret[2] = cards[i]
        end

        if #cards[i] == 3 then
            if i > banker_point then
                table.insert(ret[3], cards[i])
            else
                table.insert(little_cards, cards[i])
            end
        end

        if #cards[i] == 4 and #ret[4] == 0 then
            ret[4] = cards[i]
        end
    end

    if #ret[4] == 0 and #cards[16] == 1 and #cards[17] == 1 then
        ret[4] = {0x5E, 0x5F}
    end

    if #ret[3] == 0 and #ret[4] > 0 then
        return ret[4]
    end

    local return_ret = {}
    if #ret[3] > 0 then
        table.insert(return_ret, ret[3][1][1])
        table.insert(return_ret, ret[3][1][2])
        table.insert(return_ret, ret[3][1][3])
        if #ret[2] > 0 then
            table.insert(return_ret, ret[2][1])
            table.insert(return_ret, ret[2][2])
        elseif #little_cards > 0 then
            table.insert(return_ret, little_cards[1][1])
            table.insert(return_ret, little_cards[1][2])
        elseif #ret[3] > 1 then
            table.remove(return_ret, 3)
            table.insert(return_ret, ret[3][2][1])
            table.insert(return_ret, ret[3][2][2])
            table.insert(return_ret, ret[3][2][3])
        end
    end

    if #return_ret < 5 then
        return ret[4]
    else
        return return_ret
    end
end

function find_three_with_none(cards, banker_point)
    local boom = {}
    for i = 3, 15 do
        if #cards[i] == 3 and i > banker_point then
            return cards[i]
        end

        if #cards[i] == 4 and #boom == 0 then
            boom = cards[i]
        end
    end

    if #boom == 0 and #cards[16] == 1 and #cards[17] == 1 then
        boom = {0x5E, 0x5F}
    end
   
    return boom
end

function find_four_with_two(cards, banker_point, banker_pokers)
    local single = #banker_pokers == 6 and true or false
    local boom = {}
    local fupai = {}
    for i = 3, 17 do
        if #cards[i] == 4 and i > banker_point and #boom == 0 then
            boom = cards[i]
        end

        if single then
            if #cards[i] == 1 and #fupai < 2 then 
                table.insert(fupai, cards[i][1]) 
            end
        else
            if #cards[i] == 2 and #fupai < 4 then 
                table.insert(fupai, cards[i][1]) 
                table.insert(fupai, cards[i][2]) 
            end
        end
    end

    if #boom == 0 and #cards[16] == 1 and #cards[17] == 1 then
        boom = {0x5E, 0x5F}
    end

    if #boom ~= 4 then
        return boom 
    end

    local return_ret = {}
    if fupai[1] == 0x5E and fupai[2] == 0x5F then return boom end
    if single and #fupai < 2 then return boom end
    if single == false and #fupai < 4 then return boom end

    for i, v in ipairs(boom) do
        table.insert(return_ret, v)
    end

    for i, v in ipairs(fupai) do
        table.insert(return_ret, v)
    end

    return return_ret
end

function find_progression_cards(cards, banker_point, banker_pokers)
    local len = #banker_pokers
    local ret = {}
    local boom = {}
    for i = 3, 17 do
        if #cards[i] == 4 and #boom == 0 then boom = cards[i] end 
        if i > banker_point and i < 15 then
            if #cards[i] > 0 then 
                table.insert(ret, cards[i][1])
                if len == #ret then break end
            else
                ret = {}
            end
        end
    end

    if #boom == 0 and #cards[16] == 1 and #cards[17] == 1 then
        boom = {0x5E, 0x5F}
    end

    if #ret < len then ret = {} end

    if #ret > 0 then
        return ret
    else
        return boom
    end
end

function find_progression_pairs(cards, banker_point, banker_pokers)
    local len = #banker_pokers
    local ret = {}
    local boom = {}
    for i = 3, 15 do
        if #cards[i] == 4 and #boom == 0 then boom = cards[i] end 
        if i > banker_point and i < 15 then
            if #cards[i] >= 2 then 
                table.insert(ret, cards[i][1])
                table.insert(ret, cards[i][2])
                if len == #ret then break end
            else
                ret = {}
            end
        end        
    end

    if #boom == 0 and #cards[16] == 1 and #cards[17] == 1 then
        boom = {0x5E, 0x5F}
    end

    if #ret < len then ret = {} end

    if #ret > 0 then
        return ret
    else
        return boom
    end
end

function find_progression_suit_none(cards, banker_point, banker_pokers)
    local boom = {}
    local three_cards = {}
    local return_ret = {}
    for i = 3, 15 do
        if #cards[i] == 4 and #boom == 0 then 
            boom = cards[i] 
        end
        if i > banker_point and i < 15 and #cards[i] == 3 then
            table.insert(three_cards, i)
        end
    end

    if #boom == 0 and #cards[16] == 1 and #cards[17] == 1 then
        boom = {0x5E, 0x5F}
    end

    local len = #banker_pokers / 3
    if #three_cards < len then return boom end

    local ret = {}
    for i, v in ipairs(three_cards) do
        if #ret == 0 then 
            table.insert(ret, v)
        else
            if v - ret[#ret] ==  1 then 
                table.insert(ret, v) 
                if #ret == len then break end
            else
                ret = {}
            end
        end
    end

    if #ret == len then
        for i, v in ipairs(ret) do
            if #cards[v] == 3 then
                table.insert(return_ret, cards[v][1]) 
                table.insert(return_ret, cards[v][2]) 
                table.insert(return_ret, cards[v][3]) 
            else
                return_ret = {}
                return boom
            end
        end
    end

    if #return_ret == #banker_pokers then
        return return_ret
    else
        return boom
    end
end

function find_progression_suit_one(cards, banker_point, banker_pokers)
    local boom = {}
    local three_cards = {}
    local return_ret = {}
    local single_cards = {}
    local pairs_cards = {}
    local little_three_cards = {}
    for i = 3, 17 do
        if #cards[i] == 4 and #boom == 0 then 
            boom = cards[i]
        end
        if #cards[i] == 3 then
            if  i > banker_point and i < 15 then
                table.insert(three_cards, i)
            else
                table.insert(little_three_cards, i)
            end
        elseif #cards[i] == 2 then
            table.insert(pairs_cards, i)
        elseif #cards[i] == 1 then
            if i < 16 then
                table.insert(single_cards, i)
            end
        end
    end

    if #boom == 0 and #cards[16] == 1 and #cards[17] == 1 then
        boom = {0x5E, 0x5F}
    end

    local len = #banker_pokers / 4
    if #three_cards < len then return boom end
    if #single_cards + #pairs_cards * 2 + #little_three_cards * 3  + (#three_cards - len) * 3 < len then return boom end

    local ret = {}
    for i, v in ipairs(three_cards) do
        if #ret == 0 then 
            table.insert(ret, v)
        else
            if v - ret[#ret] ==  1 then 
                table.insert(ret, v) 
                if #ret == len then break end
            else
                ret = {}
            end
        end
    end

    if #ret ~= len then return boom end

    if #ret == len then
        for i, v in ipairs(ret) do
            if #cards[v] == 3 then
                table.insert(return_ret, cards[v][1]) 
                table.insert(return_ret, cards[v][2]) 
                table.insert(return_ret, cards[v][3]) 
            else
                return_ret = {}
                return boom
            end
        end
    end

    if #single_cards > 0 then
        for i, v in ipairs(single_cards) do
            table.insert(return_ret, cards[v][1])
            if #return_ret == #banker_pokers then break end
        end
    end

    if #return_ret < #banker_pokers and #pairs_cards > 0 then
        for i, v in ipairs(pairs_cards) do
            table.insert(return_ret, cards[v][1])
            if #return_ret == #banker_pokers then break end
            table.insert(return_ret, cards[v][2])
            if #return_ret == #banker_pokers then break end
        end
    end

    if #return_ret < #banker_pokers and #little_three_cards > 0 then
        for i, v in ipairs(little_three_cards) do
            if v < 15 then
                table.insert(return_ret, cards[v][1])
                if #return_ret == #banker_pokers then break end
                table.insert(return_ret, cards[v][2])
                if #return_ret == #banker_pokers then break end
                table.insert(return_ret, cards[v][3])
                if #return_ret == #banker_pokers then break end
            end
        end
    end

    if #return_ret < #banker_pokers and #three_cards > len then
        for i1, v1 in ipairs(three_cards) do
            local used = false
            for i2, v2 in ipairs(ret) do
                if v1 == v2 then
                    used = true
                    break
                end
            end

            if used == false then
                table.insert(return_ret, cards[v1][1])
                if #return_ret == #banker_pokers then break end
                table.insert(return_ret, cards[v1][2])
                if #return_ret == #banker_pokers then break end
                table.insert(return_ret, cards[v1][3])
                if #return_ret == #banker_pokers then break end
            end
        end
    end

    if #return_ret < #banker_pokers and cards[15] == 3 then
        table.insert(return_ret, cards[15][1])
        if #return_ret < #banker_pokers then table.insert(return_ret, cards[15][2]) end
        if #return_ret < #banker_pokers then table.insert(return_ret, cards[15][3]) end
    end

    if #return_ret == #banker_pokers then
        return return_ret
    else
        return boom
    end
end

function find_progression_suit_two(cards, banker_point, banker_pokers)
    local boom = {}
    local three_cards = {}
    local return_ret = {}

    local pairs_cards = {}
    local little_three_cards = {}
    for i = 3, 17 do
        if #cards[i] == 4 and #boom == 0 then 
            boom = cards[i] 
        end
        if #cards[i] == 3 then
            if  i > banker_point and i < 15 then
                table.insert(three_cards, i)
            else
                table.insert(little_three_cards, i)
            end
        elseif #cards[i] == 2 then
            table.insert(pairs_cards, i)
        end
    end

    if #boom == 0 and #cards[16] == 1 and #cards[17] == 1 then
        boom = {0x5E, 0x5F}
    end

    local len = #banker_pokers / 5
    if #three_cards < len then return boom end
    if #pairs_cards + #little_three_cards + (#three_cards - len) < len then return boom end

    local ret = {}
    for i, v in ipairs(three_cards) do
        if #ret == 0 then 
            table.insert(ret, v)
        else
            if v - ret[#ret] ==  1 then 
                table.insert(ret, v) 
                if #ret == len then break end
            else
                ret = {}
            end
        end
    end

    if #ret ~= len then return boom end

    if #ret == len then
        for i, v in ipairs(ret) do
            if #cards[v] == 3 then
                table.insert(return_ret, cards[v][1]) 
                table.insert(return_ret, cards[v][2]) 
                table.insert(return_ret, cards[v][3]) 
            else
                return_ret = {}
                return boom
            end
        end
    end

    if #return_ret < #banker_pokers and #pairs_cards > 0 then
        for i, v in ipairs(pairs_cards) do
            table.insert(return_ret, cards[v][1])
            table.insert(return_ret, cards[v][2])
            if #return_ret == #banker_pokers then break end
        end
    end

    if #return_ret < #banker_pokers and #little_three_cards > 0 then
        for i, v in ipairs(little_three_cards) do
            if v < 15 then
                table.insert(return_ret, cards[v][1])
                table.insert(return_ret, cards[v][2])
                if #return_ret == #banker_pokers then break end
            end
        end
    end

    if #return_ret < #banker_pokers and #three_cards > len then
        for i1, v1 in ipairs(three_cards) do
            local used = false
            for i2, v2 in ipairs(ret) do
                if v1 == v2 then
                    used = true
                    break
                end
            end

            if used == false then
                table.insert(return_ret, cards[v1][1])
                table.insert(return_ret, cards[v1][2])
                if #return_ret == #banker_pokers then break end
            end
        end
    end

    if #return_ret < #banker_pokers and cards[15] == 3 then
        table.insert(return_ret, cards[15][1])    
        table.insert(return_ret, cards[15][2])
    end

    if #return_ret == #banker_pokers then
        return return_ret
    else
        return boom
    end
end

function find_boom(cards, banker_point)
    local boom = {}
    for i = 3, 15 do
        if #cards[i] == 4 and i > banker_point then
            boom = cards[i]
            break
        end
    end

    if #boom == 0 and #cards[16] == 1 and #cards[17] == 1 then
        boom = {0x5E, 0x5F}
    end

    return boom 
end
