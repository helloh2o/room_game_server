module('place', package.seeall)

place_config = {
    ['jdddz_custom'] = {
        id = 'jdddz_custom',
        idtype = 'custom',
        name = '自定义',
        base_zhu        = 1,
        req_player_gold = 0,
        fuck_gold = 0,
        chu_tile_time   = 15, --无限制
        service_gold    = 0,
    },
    ['jdddz_gold_random1'] = {
        id = 'jdddz_gold_random1',
        idtype='random',
        name = '随机匹配',
        base_zhu        = 1,
        req_player_gold = 0,
        chu_tile_time   = 15, 
    },
	['jdddz_gold_random2'] = {
        id = 'jdddz_gold_random2',
        idtype='random',
        name = '随机匹配',
        base_zhu        = 1,
        req_player_gold = 0,
        chu_tile_time   = 15,

    },
	['jdddz_gold_random3'] = {
        id = 'jdddz_gold_random3',
        idtype='random',
        name = '随机匹配',
        base_zhu        = 1,
        req_player_gold = 0,
        chu_tile_time   = 15,
    }
}

game_config = {
    ['jdddz_gold_random1'] = {
        gametype       = 'jdddz_gold',
    
        player_count   = 3,
        ju_count       = 1,
		consume_card   = 3,
		who_pay 	   = 0,
		max_fan	       = 4,
        --men_qing_zhong_zhang = true,
        --yao_jiu_jiang_dui = true,
        --dian_gang_zi_mo = true,
        --dian_gang_dian_pao = false,   

        allow_stranger = true,
        base_gold      = 50,
        leave_gold     = 1000,
        join_gold      = 2000,

        gps            = true,
    },
    ['jdddz_gold_random2'] = {
        gametype       = 'jdddz_gold',   
    
        player_count   = 3,
        ju_count       = 1,
		consume_card   = 3,
		who_pay 	   = 0,
		max_fan	       = 4,
    
        allow_stranger = true,
        base_gold      = 200,
        leave_gold     = 4000,
        join_gold      = 8000,

        gps            = true,
    },
    ['jdddz_gold_random3'] = {
        gametype       = 'jdddz_gold',   
    
        player_count   = 3,
        ju_count       = 1,
		consume_card   = 3,
		who_pay 	   = 0,
		max_fan	       = 4,

        allow_stranger = true,
        base_gold      = 500,
        leave_gold     = 10000,
        join_gold      = 20000,

        gps            = true,
    }
}
