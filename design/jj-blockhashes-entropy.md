# Block hashes as a source of entropy

The Degen Trail and Jackpot Junction both use blockhashes as a source of entropy for their randomness.
Since the games are eternal and permissionless, we must justify that blockhashes are a *fair* source of entropy.

Our argument for fairness has two components:
1. **Empirical**: We show that, on both Base and on the Degen Chain, block hashes have historically been
fair. The tool we use to perform this analysis, `jj entropy`, can also be used to detect conditions under which
block hashes are not being fairly generated on a particular blockchain.
2. **Theoretical**: We argue that, on a public, single-sequencer network with a fast enough target block time and
high enough transaction volume (not counting transactions related to our games), the master sequencer
has enough economic disincentives to manipulating block hashes to gain an advantage in our games.

## Empirical fairness

### Analysis

The `jj entropy` command does the following:
1. It randomly samples `--samples`/`-s` blocks from the blockchain specified by `--rpc`/`-r`.
2. It simulates the random numbers that these blocks would yield for a Jackpot Junction player with
address `--player`/`-p`.
3. It calculates the entropy inherent to choosing the outcome of a Jackpot Junction roll as well as to rolling
for an item's type and terrain type.

Entropy here refers to [information theoretic entropy](https://en.wikipedia.org/wiki/Entropy_(information_theory)).

In Jackpot Junction, there are 4 item types, 7 terrain types, and 4 outcomes. On a perfectly fair chain,
the entropies of the item type distribution, terrain type distribution, and the outcome distribution
would ideally be `lg(4) = 2`, `lg(7) ~ 2.80735492206`, and `lg(4) = 2` respectively.

On the Degen chain:

```
$ bin/jj entropy -r "https://rpc.degen.tips" -p $PLAYER -s 1000
Item entropy: 1.999317
Terrain entropy: 2.792746
Outcome entropy: 1.997760
```

On Base:

```
$ bin/jj entropy -r "https://mainnet.base.org" -p $PLAYER -s 1000
Item entropy: 1.987233
Terrain entropy: 2.792224
Outcome entropy: 1.976641
```

Of course, we can estimate how far we would expect to be from the theoretical entropy over 1000 samples based
on the multinomial distribution sample variance. We do not need to do this, however. The numbers speak volumes.

### Building the tool

`jj` is open source. You can build and run it yourself.

Building `jj` requires you to have the [Go toolchain](https://go.dev/) installed.

The easiest way to build it is to use make:

```bash
make clean && make
```

But you can also directly `go build` it:

```bash
mkdir -p bin
go build -o bin/jj ./jj
```

Either command, if run from the repository root, will create an executable file called `jj` in the `bin/`
subdirectory.


## Theoretical fairness

Rollup stacks like those of Arbitrum and Optimism are designed around single sequencers validating transactions
with one of their goals being to maintain low block intervals even under load.

For public chains using these stacks which aim to have block intervals of around 2 seconds at the higher end,
assuming a heavy and unpredictable enough transaction load, the sequencer would most likely not have
enough time to solve the inverse problem of manufacturing a block hash.
