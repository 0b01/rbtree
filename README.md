# Rbtree
[![Build Status](https://travis-ci.org/rickyhan/rbtree.svg?branch=master)](https://travis-ci.org/rickyhan/rbtree)
[![Coverage Status](https://coveralls.io/repos/github/rickyhan/rbtree/badge.svg?branch=master)](https://coveralls.io/github/rickyhan/rbtree?branch=master)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/rickyhan/rbtree.svg)](https://beta.hexfaktor.org/github/rickyhan/rbtree)

## [Proposal](https://groups.google.com/forum/#!topic/elixir-lang-core/hjIW1FC-xBw)

## 

Rbtree is the underlying data structure for SortedMap and SortedSet. Elixir does not have either of these.(see proposal) Erlang has `gb_sets` and `gb_trees` which uses AA tree and are indeed very fast. According to [AA Tree](https://en.wikipedia.org/wiki/AA_tree#Performance) the performance of red-black tree should be similar.

This module support nth(tree, n) and range(tree, a..b)

## Benchmark

The following benchmark is generated from `mix bench` to run the benchmark in `bench/rbtree_bench.ex`.

Run `mix tree.prof` to profile a specific function defined in `lib/mix/tasks/rb.prof.ex`

# Benchmark

Using `mix bench -d 0.1`

```
benchmark name             iterations   average time

Tree: get size               10000000   0.01 µs/op
gbsets: get size             10000000   0.01 µs/op
gb_trees: get size           10000000   0.02 µs/op
rbdict: get size                10000   17.85 µs/op

rbdict: is_element           10000000   0.06 µs/op
gbtrees: is_defined          10000000   0.07 µs/op
gbsets: is_element           10000000   0.07 µs/op
Tree: is_element              1000000   0.12 µs/op

gbtrees: delete               1000000   0.28 µs/op
rbdict: delete                 100000   1.30 µs/op
Tree: delete                   100000   1.37 µs/op

gbsets: to_list                 10000   12.08 µs/op
Tree: to_list                   10000   19.17 µs/op
gbtrees: to_list                 5000   31.94 µs/op
rbdict: to_list                  5000   32.04 µs/op

gbtrees: lookup                  2000   96.47 µs/op
rbdict: lookup                   1000   115.38 µs/op
Tree: lookup                     1000   196.22 µs/op

gb_trees: new from_list          5000   58.64 µs/op
gb_sets: new from_list           5000   66.36 µs/op
rbdict: new from_list             500   482.26 µs/op
Tree: new from_list               200   954.50 µs/op

gb_trees: words from_list         500   304.65 µs/op
gb_sets: words from_list          500   559.94 µs/op
rbdict: words from_list            50   6051.94 µs/op
Tree: words from_orddict           20   8953.30 µs/op

Tree: range                  10000000   0.03 µs/op
Tree: nth                     1000000   0.96 µs/op

```

