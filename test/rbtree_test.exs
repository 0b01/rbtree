defmodule RbtreeTest do
  use ExUnit.Case

  alias Rbtree.Leaf
  alias Rbtree.Node

  import Rbtree

  doctest Rbtree

  test "should create empty tree" do
    assert empty() == %Rbtree{node: Leaf}
    assert null?(empty())
    assert height(empty()) == 0
  end

  test "should create singleton" do
    assert singleton(0) == %Rbtree{node: %Node{
        color: :black,
        depth: 1,
        key: 0,
        left: Leaf,
        right: Leaf
      }}
  end

  test "create a rbtree from list" do
    tree = Rbtree.from_list(1..4 |> Enum.map(&Integer.to_string/1) |>Enum.to_list)
    assert ["4", "3", "2", "1"] == tree|> Rbtree.to_list

    tree = Rbtree.from_list([{"a", "test"}, "b"])
    assert ["b", {"a", "test"}] == tree|> Rbtree.to_list
    assert ordered?(tree)
  end

  test "initializing a red black tree" do
    assert %Rbtree{} == Rbtree.new
    assert 0 == Rbtree.new.size
    assert [3, 2, 1] == [1,2,3] |> Rbtree.new |> Rbtree.to_list
  end


  test "if key is in tree" do
    assert false == empty() |> member?("new")
    assert singleton("new") |> member?("new")
    assert false == singleton("new") |> member?("nw")
  end

  test "deletion" do
    tree = Rbtree.from_list(1..4 |> Enum.map(&Integer.to_string/1) |>Enum.to_list)
    assert tree |> delete(1) |> delete(2) |> size == 2
  end

  test "should put everything to list or map" do
    assert [{"new", "test"}] == singleton("new", "test") |> to_list
    assert %{"new" => "test"} == singleton("new", "test") |> to_map
  end

  test "should conver tree to string" do
    str_tree = singleton("new", "test") |> Rbtree.to_string
    assert "\n(size:0)\nblack { \"new\", \"test\" }(d:1)\n+ \n+ \n" == str_tree
  end


  test "size" do
    tree = Rbtree.from_list(1..20 |>  Enum.map(&({&1, &1})) |>Enum.to_list)
    assert tree.size == size(tree)
  end

end
