# Rbtree
[![Build Status](https://travis-ci.org/rickyhan/rbtree.svg?branch=master)](https://travis-ci.org/rickyhan/rbtree)
[![Coverage Status](https://coveralls.io/repos/github/rickyhan/rbtree/badge.svg?branch=master)](https://coveralls.io/github/rickyhan/rbtree?branch=master)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/rickyhan/rbtree.svg)](https://beta.hexfaktor.org/github/rickyhan/rbtree)

## [Proposal](https://groups.google.com/forum/#!topic/elixir-lang-core/hjIW1FC-xBw)

## 

Rbtree is the underlying data structure for SortedMap and SortedSet. Elixir does not have either of these.(see proposal) Erlang has `gb_sets` and `gb_trees` which uses AA tree and are indeed very fast. According to [AA Tree](https://en.wikipedia.org/wiki/AA_tree#Performance) the performance of red-black tree should be similar.

Todo:

1. ~~Basic functionality~~
2. Benchmark and optimize
3. Add documentation
4. Implement Wrapper modules SortedMap and SortedSet

## Benchmark

The following benchmark is generated from `mix bench` to run the benchmark in `bench/rbtree_bench.ex`.

Run `mix tree.prof` to profile a specific function defined in `lib/mix/tasks/rb.prof.ex`

```
benchmark name             iterations   average time
Tree: get size                1000000   0.02 µs/op
gbsets: get size              1000000   0.02 µs/op
gb_trees: get size            1000000   0.02 µs/op
rbdict: get size                  500   33.79 µs/op

rbdict: is_element            1000000   0.09 µs/op
gbtrees: is_defined           1000000   0.09 µs/op
gbsets: is_element             100000   0.11 µs/op
Tree: is_element               100000   0.19 µs/op

rbdict: lookup                    100   146.07 µs/op
gbtrees: lookup                   100   196.36 µs/op
Tree: lookup                       50   398.28 µs/op

gbtrees: delete                100000   0.36 µs/op
Tree: delete                    10000   2.82 µs/op
rbdict: delete                  20000   3.73 µs/op

gbsets: to_list                  1000   38.92 µs/op
Tree: to_list                    1000   47.09 µs/op
rbdict: to_list                   500   59.77 µs/op
gbtrees: to_list                  200   87.36 µs/op

gb_trees: new from_list           500   95.28 µs/op
gb_sets: new from_list            100   146.88 µs/op
rbdict: new from_list              50   949.64 µs/op
Tree: new from_list                10   1769.70 µs/op

gb_trees: words from_list          10   2206.50 µs/op
gb_sets: words from_list           10   2982.90 µs/op
Tree: words from_orddict            1   16201.00 µs/op
rbdict: words from_list             1   17812.00 µs/op
```

