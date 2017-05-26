defmodule Tree.Bench do
  use Benchfella

  @list Enum.to_list(1000..1)
  @dict @list |> Enum.map(&({&1,nil}))

  @tree Tree.from_list(@dict)
  @rbdict :rbdict.from_list(@dict)
  @gbsets :gb_sets.from_list(@list)
  @gbtrees :gb_trees.from_orddict(@dict)
# -------------------------
# This one is the key metrics

  # bench "rbdict: new", [words: words()] do
  #   :rbdict.from_list(words)
  # end

  # bench "gb_sets: new", [words: words()] do
  #   :gb_sets.from_list(words)
  # end

  # bench "gb_trees: new", [words: words()] do
  #   :gb_trees.from_orddict(words)
  # end

  # bench "Tree: new", [words: words()] do
  #   Tree.from_list(words)
  # end

# -------------------------


  # bench "rbdict: new" do
  #   :rbdict.from_list(@dict)
  # end

  # bench "gb_sets: new" do
  #   :gb_sets.from_list(@dict)
  # end

  # bench "gb_trees: new" do
  #   :gb_trees.from_orddict(@dict)
  # end

  # bench "Tree: new" do
  #   Tree.from_list(@dict)
  # end

# -------------------------

  # bench "Tree: delete" do
  #   Tree.delete(@tree, 100)
  # end

  # bench "rbdict: delete" do
  #   :rbdict.erase(100, @rbdict)
  # end

  # bench "gbsets: delete" do
  #   :gb_sets.delete(100,@gbsets)
  # end

  # bench "gbtrees: delete" do
  #   :gb_trees.delete_any(100,@gbtrees)
  # end

# -------------------------

  # bench "Tree: to_list" do
  #   Tree.to_list(@tree)
  # end

  # bench "rbdict: to_list" do
  #   :rbdict.to_list(@rbdict)
  # end

  # bench "gbsets: to_list" do
  #   :gb_sets.to_list(@gbsets)
  # end

  # bench "gbtrees: to_list" do
  #   :gb_trees.to_list(@gbtrees)
  # end

# -------------------------

  # bench "tree: get size" do
  #     Tree.size(@tree)
  # end

  # bench "rbdict: get size" do
  #   :rbdict.size(@rbdict)
  # end

  # bench "gbsets: get size" do
  #   :gb_sets.size(@gbsets)
  # end

# -------------------------
  # bench "tree: new" do
  #     Tree.new()
  # end

  # bench "rbdict: new" do
  #   :rbdict.new()
  # end

  # bench "gbsets: new" do
  #   :gb_sets.new()
  # end
# -------------------------

  bench "tree: is_element" do
    Tree.member?(@tree, 10)
  end

  bench "rbdict: is_element" do
    :rbdict.is_key(10, @rbdict)
  end

  bench "gbsets: is_element" do
    :gb_sets.is_element(10, @gbsets)
  end

  bench "gbtrees: is_defined" do
    :gb_trees.is_defined(10, @gbtrees)
  end

# -------------------------
  defp words do
    {:ok, lines} = File.read "bench/female-names.txt"
    lines |> String.split("\n") |> Enum.map(&{&1, &1})
  end
end