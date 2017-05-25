defmodule RbtreeTest do
  use ExUnit.Case

  import Rbtree

  doctest Rbtree

  test "should create empty tree" do
    assert empty() == %Rbtree{node: nil}
    assert null?(empty())
    assert height(empty()) == 0
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
    for i <- 1..16 do
      tree = Rbtree.from_list(1..i |>  Enum.map(&({&1, &1})) |>Enum.to_list)
      # IO.puts tree |> Rbtree.to_string
      assert tree.size == size(tree)
    end
  end

  test "nth" do
    range = 1..10000
    tree = Rbtree.from_list(range |>  Enum.map(&({&1, &1})) |>Enum.to_list)
    for i <- range do
      assert tree |> nth(i-1) == {i,i}
    end
  end

end
