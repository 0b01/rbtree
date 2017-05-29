# Rbtree
[![Build Status](https://travis-ci.org/rickyhan/rbtree.svg?branch=master)](https://travis-ci.org/rickyhan/rbtree)
[![Coverage Status](https://coveralls.io/repos/github/rickyhan/rbtree/badge.svg?branch=master)](https://coveralls.io/github/rickyhan/rbtree?branch=master)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/rickyhan/rbtree.svg)](https://beta.hexfaktor.org/github/rickyhan/rbtree)

## [Proposal](https://groups.google.com/forum/#!topic/elixir-lang-core/hjIW1FC-xBw)

## 

Ordinal access to a sorted treemap and treeset 100% Elixir

## Example

```elixir
range = 1..10
tree = Tree.from_list(range |>  Enum.map(&({&1, &1})) |>Enum.to_list)
for i <- range do
  assert tree |> nth(i-1) == {{i,i}, nil}
end

# Incorrect index will always return nil
tree = Tree.from_list(1..10 |> Enum.to_list)
assert tree |> nth(10) == nil
assert tree |> nth(0) == {1, nil}
assert tree |> nth(1) == {2, nil}
assert tree |> nth(-1) == {10, nil}

tree = Tree.from_list(1..40 |> Enum.to_list)
assert [{1, nil}] == tree |> range(0, 0)
assert [{40, nil}] == tree |> range(-1, 0)
assert nil == tree |> range(10, 1)
assert nil == tree |> range(0, 1000)
assert [{1, nil},{2, nil}] == tree |> range(0, 1)
assert [{1, nil},{2, nil},{3,nil}] == tree |> range(0, 2)
assert [{1, nil},{2, nil},{3, nil}, {4, nil}] == tree |> range(0, 3)
assert [{2, nil},{3,nil},{4,nil}] == tree |> range(1, 3)
```

## Functions

```elixir
comparator/2               delete/2
delete_max/1               delete_min/1
difference/2               do_to_string/2
empty/0                    fetch/2
filter_range/3             filter_range/4
filter_range/5             filter_range_by_value/3
filter_range_by_value/4    filter_range_by_value/5
from_list/1                from_list/2
from_orddict/1             from_orddict/2
get/3                      get_and_update/3
has_key?/2                 height/1
index/2                    insert/3
intersection/2             join/3
maximum/1                  member?/2
merge/2                    minimum/1
new/0                      new/1
nth/2                      null?/1
pop/2                      range/3
reduce/3                   reduce_nodes/3
reduce_nodes/4             set/3
singleton/1                singleton/2
size/1                     split/2
to_list/1                  to_list/2
to_map/1                   to_string/1
union/2                    valid?/1
``````

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

