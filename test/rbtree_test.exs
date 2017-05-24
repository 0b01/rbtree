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
        size: 1,
        left: Leaf,
        right: Leaf
      }}
  end

  test "should test if key is in tree" do
    assert false == empty() |> member?("new")
    assert singleton("new") |> member?("new")
    assert false == singleton("new") |> member?("nw")
  end

  # test "should put everything to list or map" do
  #   assert [{"new", "test"}] == singleton("new", "test") |> to_list
  #   assert %{"new" => "test"} == singleton("new", "test") |> to_map
  # end

  # test "should conver tree to string" do
  #   str_tree = singleton("new", "test") |> Rbtree.to_string
  #   assert "black {\"new\", \"test\"}(1)\n+ \n+ \n" == str_tree
  # end

  test "create a rbtree from list" do
    tree = Rbtree.from_list(["a", "b", "ab", "c", "e", "f", "g", "d"])
    assert ordered?(tree |> to_list |> Enum.reverse)
  end

end
