package entropy

import (
	"errors"
	"math"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
)

var ErrParseBlockHash error = errors.New("could not parse block number")

func Entropies(blocks []BlockResult, player string) (float64, float64, float64) {
	one := big.NewInt(1)
	two := big.NewInt(2)
	four := big.NewInt(4)
	seven := big.NewInt(7)
	twenty := big.NewInt(20)
	onehundredeighteen := big.NewInt(118)

	outcomeMask := new(big.Int)
	outcomeMask.Exp(two, twenty, nil)
	outcomeMask.Sub(outcomeMask, one)

	terrainMask := new(big.Int)
	terrainMask.Exp(two, onehundredeighteen, nil)
	terrainMask.Sub(terrainMask, one)
	terrainMask.Lsh(terrainMask, 20)

	itemMask := new(big.Int)
	itemMask.Set(terrainMask)
	itemMask.Lsh(itemMask, 118)

	index := make(map[string]bool)
	itemReductionFrequencies := make(map[int64]int)
	terrainReductionFrequencies := make(map[int64]int)
	outcomeReductionFrequencies := make(map[int64]int)

	for _, block := range blocks {
		_, blockNumberProcessed := index[block.Number]
		if !blockNumberProcessed {
			index[block.Number] = true

			blockhash := common.HexToHash(block.Hash)
			address := common.HexToAddress(player)
			data := append(blockhash.Bytes(), address.Bytes()...)

			hashBytes := crypto.Keccak256(data)

			value := new(big.Int)
			value.SetBytes(hashBytes)

			itemRNG := new(big.Int)
			itemRNG.And(value, itemMask)
			itemRNG.Rsh(itemRNG, 138)
			itemRNG.Mod(itemRNG, four)
			itemReduction := itemRNG.Int64()
			_, itemReductionExists := itemReductionFrequencies[itemReduction]
			if itemReductionExists {
				itemReductionFrequencies[itemReduction] += 1
			} else {
				itemReductionFrequencies[itemReduction] = 1
			}

			terrainRNG := new(big.Int)
			terrainRNG.And(value, terrainMask)
			terrainRNG.Rsh(terrainRNG, 20)
			terrainRNG.Mod(terrainRNG, seven)
			terrainReduction := terrainRNG.Int64()
			_, terrainReductionExists := terrainReductionFrequencies[terrainReduction]
			if terrainReductionExists {
				terrainReductionFrequencies[terrainReduction] += 1
			} else {
				terrainReductionFrequencies[terrainReduction] = 1
			}

			outcomeRNG := new(big.Int)
			outcomeRNG.And(value, outcomeMask)
			outcomeRNG.Mod(outcomeRNG, four)
			outcomeReduction := outcomeRNG.Int64()
			_, outcomeReductionExists := outcomeReductionFrequencies[outcomeReduction]
			if outcomeReductionExists {
				outcomeReductionFrequencies[outcomeReduction] += 1
			} else {
				outcomeReductionFrequencies[outcomeReduction] = 1
			}
		}
	}

	var itemEntropy, terrainEntropy, outcomeEntropy float64 = 0, 0, 0
	for _, frequency := range itemReductionFrequencies {
		p := float64(frequency) / float64(len(index))
		itemEntropy -= p * math.Log2(p)
	}
	for _, frequency := range terrainReductionFrequencies {
		p := float64(frequency) / float64(len(index))
		terrainEntropy -= p * math.Log2(p)
	}
	for _, frequency := range outcomeReductionFrequencies {
		p := float64(frequency) / float64(len(index))
		outcomeEntropy -= p * math.Log2(p)
	}

	return itemEntropy, terrainEntropy, outcomeEntropy
}
