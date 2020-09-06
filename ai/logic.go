package ai

import (
	"encoding/json"
	"github.com/golang/protobuf/proto"
	"server/leaf/log"
	"server/protobuf"
	"server/vm"
	"time"
)

func (c *Client) doLogic(p *protobuf.Protocol) {
	var err error
	switch int(p.Id) {
	case sc_protocol_pack:
		var pack protobuf.ScProtocolPack
		err = proto.Unmarshal(p.Content, &pack)
		if err != nil {
			log.Error("Unmarshal ScProtocolPack %s", err)
		} else {
			for _, per := range pack.Pack {
				c.doLogic(per)
			}
		}
	case sc_enter_room:
		var enter ScEnterRoom
		err = proto.Unmarshal(p.Content, &enter)
		if err != nil {
			log.Error("%s", err)
		} else {
			c.ready()
		}
	case sc_enter_room_failed:
		var failed ScEnterRoomFailed
		err = proto.Unmarshal(p.Content, &failed)
		if err != nil {
			log.Error("%s", err)
		} else {
			log.Error("Enter Room Failed %s ", failed.Desc)
		}
	// 游戏开始
	case sc_start_game:
		var startGame ScStartGame
		err = proto.Unmarshal(p.Content, &startGame)
		if err != nil {
			log.Error("ScStartGame %s", err)
		} else {
			log.Debug("玩家 %s, 游戏开始 数据 %+v", c.Player.NickName, startGame)
			c.GameInfo = &startGame
		}
	case sc_game_show_actions:
		var actions ScGameShowActions
		err = proto.Unmarshal(p.Content, &actions)
		if err != nil {
			log.Error("ScStartGame %s", err)
		} else {
			//log.Debug("玩家 %s, ScGameShowActions 数据 %+v", c.Player.NickName, actions.ShowActions)
			first := actions.ShowActions[0]
			if first != 5 { // 不是出牌
				action := CsGameAction{Id: uint32(first), Reply: 1}
				actionData, _ := proto.Marshal(&action)
				data, _ := proto.Marshal(&Protocol{Content: actionData, Id: uint32(cs_game_action)})
				c.write(0, data)
			}
		}
	case sc_game_action_notify:
		var notify ScGameActionNotify
		err = proto.Unmarshal(p.Content, &notify)
		if err != nil {
			log.Error("ScGameActionNotify %s", err)
		} else {
			if notify.ActId == 5 && len(notify.Pokers) > 0 {
				c.Notify = &notify
			}
		}
	case sc_game_turn:
		// 模拟等待,玩家考虑时间1s
		//time.Sleep(time.Second)
		var turn ScGameTurn
		err = proto.Unmarshal(p.Content, &turn)
		if err != nil {
			log.Error("ScStartGame %s", err)
		} else {
			log.Debug("玩家 %s, ScGameTurn 数据 %+v", c.Player.NickName, turn.ShowActions)
			first := turn.ShowActions[0]
			if first != 5 { // 不是出牌
				action := CsGameAction{Id: uint32(first), Reply: 1}
				actionData, _ := proto.Marshal(&action)
				data, _ := proto.Marshal(&Protocol{Content: actionData, Id: uint32(cs_game_action)})
				c.write(0, data)
			} else {
				/*// 出牌
				if c.GameInfo.YouSeqInfo.SeatIndex == c.Dizhu {
					pokers := c.GameInfo.YouSeqInfo.HandSeq.Pokers
					action := CsGameAction{Id: uint32(first), Pokers: pokers[:1]}
					actionData, _ := proto.Marshal(&action)
					data, _ := proto.Marshal(&Protocol{Content: actionData, Id: uint32(cs_game_action)})
					c.write(0, data)
				} else {
					action := CsGameAction{Id: uint32(first)}
					actionData, _ := proto.Marshal(&action)
					data, _ := proto.Marshal(&Protocol{Content: actionData, Id: uint32(cs_game_action)})
					c.write(0, data)
				}*/
				// lua play
				seq, err := json.Marshal(c.GameInfo.YouSeqInfo)
				if c.GameInfo.YouSeqInfo == nil || err != nil {
					log.Error("marshal game info err %v", err)
					seq = []byte("{}")
				}
				notifyInfo, err := json.Marshal(c.Notify)
				if c.Notify == nil || err != nil {
					log.Error("marshal notifyInfo info err %v", err)
					notifyInfo = []byte("{}")
				}
				log.Debug("SEQ ==》 %s", string(seq))
				log.Debug("NOTIFY ==》 %s", string(notifyInfo))
				calldata := vm.NewCallData("get_auto_action_pokers", []interface{}{string(seq), string(notifyInfo)}, 1)
				_vm.CallChan <- calldata
				result := <-calldata.Result
				action := CsGameAction{Id: 5}
				if result.Ok {
					pokers, ok := result.Data[0].([]interface{})
					if ok {
						pv := make([]int32, 0)
						for _, v := range pokers {
							p := v.(int64)
							pv = append(pv, int32(p))
						}
						action.Pokers = pv
					}
					actionData, _ := proto.Marshal(&action)
					data, _ := proto.Marshal(&Protocol{Content: actionData, Id: uint32(cs_game_action)})
					c.write(0, data)
				}
			}
		}
	case sc_dizhu_info:
		var dizhu ScDizhuInfo
		err = proto.Unmarshal(p.Content, &dizhu)
		if err != nil {
			log.Error("ScStartGame %s", err)
		} else {
			c.Dizhu = dizhu.DizhuSeat
			if c.GameInfo.YouSeqInfo.SeatIndex == c.Dizhu {
				c.GameInfo.YouSeqInfo.HandSeq.Pokers = append(c.GameInfo.YouSeqInfo.HandSeq.Pokers, dizhu.DizhuPokers...)
			}
		}
	case sc_game_action:
		var gameAction ScGameAction
		err = proto.Unmarshal(p.Content, &gameAction)
		if err != nil {
			log.Error("ScStartGame %s", err)
		} else {
			if gameAction.ActId == 5 {
				if gameAction.ActedHandSeq != nil {
					c.GameInfo.YouSeqInfo.HandSeq.Pokers = gameAction.ActedHandSeq.Pokers
					if gameAction.ActPokersType != 0 && gameAction.NextTurn != 0 {
						if c.Notify == nil {
							c.Notify = &ScGameActionNotify{}
						}
						c.Notify.Pokers = gameAction.Pokers
						c.Notify.ActPokersType = gameAction.ActPokersType
						c.Notify.NextTurn = gameAction.NextTurn
						c.Notify.ActSeatIndex = c.GameInfo.YouSeqInfo.SeatIndex
					}
				}
			}
			if gameAction.ActedHandSeq != nil {
				log.Release("玩家 %s, 牌 %+v", c.Player.NickName, gameAction.ActedHandSeq.Pokers)
			}

		}
	case sc_end_game:
		log.Release("玩家 %s,Game Over.", c.Player.NickName)
		// 继续准备
		c.Notify = nil
		c.ready()
	}

}

func (c *Client) ready() {
	y := time.Now().Unix() % 2
	// ready 准备
	ready := CsReadyGame{Mingpai: int32(y)}
	readyData, _ := proto.Marshal(&ready)
	data, _ := proto.Marshal(&Protocol{Content: readyData, Id: uint32(cs_ready_game)})
	c.write(0, data)
}
