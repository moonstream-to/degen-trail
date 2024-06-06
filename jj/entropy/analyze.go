package entropy

import (
	"errors"
	"math"
	"math/big"
)

var ErrParseBlockHash error = errors.New("could not parse block number")

func EntropyModN(blocks []BlockResult, N int) (float64, error) {
	index := make(map[string]bool)
	reductionFrequencies := make(map[int64]int)

	base := new(big.Int)
	base.SetInt64(int64(N))
	for _, block := range blocks {
		_, blockNumberProcessed := index[block.Number]
		if !blockNumberProcessed {
			index[block.Number] = true

			value := new(big.Int)
			_, ok := value.SetString(block.Hash, 0)
			if !ok {
				return 0, ErrParseBlockHash
			}

			reduction := value.Mod(value, base).Int64()

			_, reductionExists := reductionFrequencies[reduction]
			if reductionExists {
				reductionFrequencies[reduction] += 1
			} else {
				reductionFrequencies[reduction] = 1
			}
		}
	}

	var entropy float64 = 0
	for _, frequency := range reductionFrequencies {
		p := float64(frequency) / float64(len(index))
		entropy -= p * math.Log2(p)
	}

	return entropy, nil
}
