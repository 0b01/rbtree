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
  end

  test "initializing a red black tree" do
    assert %Rbtree{} == Rbtree.new
    assert 0 == Rbtree.new.size
    assert [3, 2, 1] == [1,2,3] |> Rbtree.new |> Rbtree.to_list
  end


  test "to_list" do
    empty_tree = Rbtree.new
    bigger_tree = Rbtree.new([d: 1, b: 2, c: 3, a: 4])
    assert [] == Rbtree.to_list empty_tree

    # It should return the elements in order
    assert (Enum.reverse [{:a, 4}, {:b, 2}, {:c, 3}, {:d, 1}]) == Rbtree.to_list bigger_tree
    assert 4 == bigger_tree.size
  end


  test "insert" do
    red_black_tree = Rbtree.insert Rbtree.new, 1, :bubbles
    assert [{1, :bubbles}] == Rbtree.to_list red_black_tree
    assert 1 == red_black_tree.size

    red_black_tree = Rbtree.insert red_black_tree, 0, :walrus
    assert (Enum.reverse [{0, :walrus}, {1, :bubbles}]) == Rbtree.to_list red_black_tree
    assert 2 == red_black_tree.size
  end


  test "strict equality" do
    tree = Rbtree.new([{1, :bubbles}])
    updated = Rbtree.insert(tree, 1.0, :walrus)

    assert 2 == Rbtree.size(updated)

    # Deletes
    # We convert to lists so that the comparison ignores node colors
    assert Rbtree.to_list(Rbtree.new([{1, :bubbles}])) ==
           Rbtree.to_list(Rbtree.delete(updated, 1.0))
    assert Rbtree.to_list(Rbtree.new([{1.0, :walrus}])) ==
           Rbtree.to_list(Rbtree.delete(updated, 1))

    # Search
    assert :walrus == Rbtree.get(updated, 1.0)
    assert :bubbles == Rbtree.get(updated, 1)

    assert true == Rbtree.has_key?(updated, 1.0)
    assert true == Rbtree.has_key?(updated, 1)
  end

  test "set and get" do
    tree = Rbtree.new([{"example", "test"}])
    assert get(tree, "example") == "test"

    tree = set(tree, "example", 1)
    assert get(tree, "example") == 1

    tree = Rbtree.new([d: 1, b: 2, f: 3, g: 4, c: 5, a: 6, e: 7])
    assert 2 == get(tree, :b)
    assert 6 == get(tree, :a)
    assert 3 == get(tree, :f)
    assert 1 == get(tree, :d)
    assert 7 == get(tree, :e)
    assert 4 == get(tree, :g)
    assert 5 == get(tree, :c)
  end

  test "if key is in tree" do
    assert false == empty() |> member?("new")
    assert singleton("new") |> member?("new")
    assert false == singleton("new") |> member?("nw")
  end

  test "deletion" do
    tree = Rbtree.from_list(1..4 |> Enum.map(&Integer.to_string/1) |>Enum.to_list)
    assert tree |> delete(1) |> delete(2) |> size == 2

    initial_tree = Rbtree.new([d: 1, b: 2, c: 3, a: 4])
    assert 4 == initial_tree.size
    pruned_tree = delete(initial_tree, :c)

    assert 3 == pruned_tree.size
    IO.puts pruned_tree |> Rbtree.to_string
    assert Enum.reverse([{:a, 4}, {:b, 2}, {:d, 1}]) == to_list pruned_tree

    assert 2 == delete(pruned_tree, :a).size
    assert Enum.reverse([{:b, 2}, {:d, 1}]) == to_list delete(pruned_tree, :a)

    assert [] == to_list delete new, :b


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

  test "get the nth element from the tree" do
    range = 1..10
    tree = Rbtree.from_list(range |>  Enum.map(&({&1, &1})) |>Enum.to_list)
    for i <- range do
      assert tree |> nth(i-1) == {i,i}
    end

    # Incorrect index will always return nil
    tree = Rbtree.from_list(1..1|>  Enum.map(&({&1, &1})) |>Enum.to_list)
    assert tree |> nth(10) == nil
    assert tree |> nth(1) == nil
    assert tree |> nth(0) == {1,1}
    assert tree |> nth(-1) == nil
  end

end
