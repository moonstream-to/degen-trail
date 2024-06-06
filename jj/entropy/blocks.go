package entropy

import (
	"bytes"
	"crypto/rand"
	"encoding/json"
	"math/big"
	"net/http"
)

// This struct represents the result in a from the Ethereum JSON-RPC API for the `eth_getBlockByNumber` method.
// BlockResult represents the object stored under the "result" key of the sample response documented with BlockResponse below.
type BlockResult struct {
	BaseFeePerGas    string   `json:"baseFeePerGas"`
	Difficulty       string   `json:"difficulty"`
	ExtraData        string   `json:"extraData"`
	GasLimit         string   `json:"gasLimit"`
	GasUsed          string   `json:"gasUsed"`
	Hash             string   `json:"hash"`
	L1BlockNumber    string   `json:"l1BlockNumber"`
	LogsBloom        string   `json:"logsBloom"`
	Miner            string   `json:"miner"`
	MixHash          string   `json:"mixHash"`
	Nonce            string   `json:"nonce"`
	Number           string   `json:"number"`
	ParentHash       string   `json:"parentHash"`
	ReceiptsRoot     string   `json:"receiptsRoot"`
	SendCount        string   `json:"sendCount"`
	SendRoot         string   `json:"sendRoot"`
	Sha3Uncles       string   `json:"sha3Uncles"`
	Size             string   `json:"size"`
	StateRoot        string   `json:"stateRoot"`
	Timestamp        string   `json:"timestamp"`
	TotalDifficulty  string   `json:"totalDifficulty"`
	Transactions     []string `json:"transactions"`
	TransactionsRoot string   `json:"transactionsRoot"`
	Uncles           []string `json:"uncles"`
}

// This represents the full API response from the Ethereum JSON-RPC API for the `eth_getBlockByNumber` method.
// A sample:
//
//	{
//	  "jsonrpc": "2.0",
//	  "result": {
//	    "baseFeePerGas": "0x50a5ff0",
//	    "difficulty": "0x1",
//	    "extraData": "0x8ccde7ad600340184153fae21ff4bcdf4b671e8feff6fe1fe0d3d7cf06b6582a",
//	    "gasLimit": "0x4000000000000",
//	    "gasUsed": "0x1e525c",
//	    "hash": "0x50caeaad3fc310c62608edc880b3796685804c69652bec8e822eb7ac09e3978d",
//	    "l1BlockNumber": "0xeb875a",
//	    "logsBloom": "0x00300000000000001000000080000800000000000080000800000000000000100000020411000000000040000600000008800000000000000008000000002000000000000000010000080008000000300000000040000000000000008800000000000000000010200000000000000000000020000000000000000030000000000000021000080000000000000000000000000109008100080000006000001000080100000000000000000000010000020001000100000000000000100000000000000002000000000000000000000000000200000008041020000004000000004000000001040000010000000010000000000000002000400000280000200000",
//	    "miner": "0xa4b000000000000000000073657175656e636572",
//	    "mixHash": "0x0000000000004fa90000000000eb875a000000000000000a0000000000000000",
//	    "nonce": "0x000000000001eec6",
//	    "number": "0x1598762",
//	    "parentHash": "0x9cb6e1ec426087814358d95bb33600fd86cb52fd8d2c880f32a7a7477a3ac58f",
//	    "receiptsRoot": "0xad2133328c54466c80027988ee256d817f7893fe8a4eeb754d75e90a33f1396a",
//	    "sendCount": "0x4fa9",
//	    "sendRoot": "0x8ccde7ad600340184153fae21ff4bcdf4b671e8feff6fe1fe0d3d7cf06b6582a",
//	    "sha3Uncles": "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
//	    "size": "0xc4b",
//	    "stateRoot": "0xa71abab49323e20d707666686fe4c246a6b66df5ecad33ecfea3a119c2dffb03",
//	    "timestamp": "0x66616ba9",
//	    "totalDifficulty": "0x1598763",
//	    "transactions": [
//	      "0x0274307a8f9a76124e4d47f4a33d66bd11748364069362938223150870de73ea",
//	      "0x047f120188a517918c9202e34108e57282cac7c9b4aa0e683c201fa41c318709",
//	      "0x266a9bb8c0c5c0d0aad50e06c3622a2cadc3ca89946303e2b899d09e7ca0cdeb",
//	      "0x29df4a4250d781657916d87f9d22ca4bab0eeaa4148ea07f98e65839c8665029",
//	      "0x7fb1b26c76e92b4694530a94cd0e42737b504ca1c988028ecfa72a8fbb4e832b",
//	      "0x0143c88d54d1a18e738f14247d50036acb621dfa1352a4f4e3172e913d1b021f",
//	      "0xe9ecc6f5e657816b5bbe9f8793dd682976ef4c48daf0b36acee58b227cae5c9a",
//	      "0xa904a8576906c88034068767097a8207c1323376b5778506505582ee173d9749",
//	      "0x23a22279e18acb856b902e86f175d42c84c30a2db065e8d23c8b7165dae34325",
//	      "0xada84b9003f4fb52d4b7257f085a99d8279fccc27276bb1bf64167b895752feb",
//	      "0xa10c069e787265d89cc55c2d283725483c4b1d20909d50a3efa834cb90b2e852"
//	    ],
//	    "transactionsRoot": "0x34bc3308bbd0a36afc7b453bdbf28d14fbfae5215c5b7b7601404cc05f593665",
//	    "uncles": []
//	  },
//	  "id": 0
//	}
type BlockResponse struct {
	JSONRPC string      `json:"jsonrpc"`
	Result  BlockResult `json:"result"`
	ID      int         `json:"id"`
}

func GetBlock(client *http.Client, rpc string, blockNumber *big.Int, id int) (BlockResult, error) {
	blockNumberParameter := "latest"
	if blockNumber != nil {
		blockNumberParameter = "0x" + blockNumber.Text(16)
	}

	body := map[string]interface{}{
		"jsonrpc": "2.0",
		"method":  "eth_getBlockByNumber",
		"params":  []interface{}{blockNumberParameter, false},
		"id":      id,
	}

	bodyJSON, marshalErr := json.Marshal(body)
	if marshalErr != nil {
		return BlockResult{}, marshalErr
	}

	request, requestErr := http.NewRequest("POST", rpc, bytes.NewBuffer(bodyJSON))
	if requestErr != nil {
		return BlockResult{}, requestErr
	}

	request.Header.Set("Content-Type", "application/json")

	response, responseErr := client.Do(request)
	if responseErr != nil {
		return BlockResult{}, responseErr
	}

	var blockResponse BlockResponse
	unmarshalErr := json.NewDecoder(response.Body).Decode(&blockResponse)
	if unmarshalErr != nil {
		return BlockResult{}, unmarshalErr
	}

	return blockResponse.Result, nil
}

func GetBlockAsync(client *http.Client, rpc string, blockNumber *big.Int, id int, blocksChan chan<- BlockResult, errsChan chan<- error) {
	block, blockErr := GetBlock(client, rpc, blockNumber, id)
	if blockErr != nil {
		errsChan <- blockErr
	} else {
		blocksChan <- block
	}
}

func GetRandomBlocks(client *http.Client, rpc string, latestBlockNumber *big.Int, samples int) ([]BlockResult, error) {
	if latestBlockNumber == nil {
		latestBlock, latestBlockErr := GetBlock(client, rpc, nil, 0)
		if latestBlockErr != nil {
			return []BlockResult{}, latestBlockErr
		}
		latestBlockNumber = new(big.Int)
		latestBlockNumber.SetString(latestBlock.Number, 0)
	}

	blocksChan := make(chan BlockResult)
	errsChan := make(chan error)

	blocks := make([]BlockResult, samples)
	for i := 0; i < samples; i++ {
		blockNumber, sampleErr := rand.Int(rand.Reader, latestBlockNumber)
		if sampleErr != nil {
			return blocks, sampleErr
		}

		go GetBlockAsync(client, rpc, blockNumber, i, blocksChan, errsChan)
	}

	numProcessed := 0
	for {
		select {
		case block := <-blocksChan:
			blocks[numProcessed] = block
			numProcessed++
			if numProcessed == samples {
				return blocks, nil
			}
		case blockErr := <-errsChan:
			return blocks, blockErr
		}
	}
}
