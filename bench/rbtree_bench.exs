defmodule Tree.Bench do
  use Benchfella, duration: 0.5

  @list Enum.to_list(1..1000)
  @dict @list |> Enum.map(&({&1,nil}))

  @tree Tree.from_orddict(@dict)
  @rbdict :rbdict.from_list(@dict)
  @gbsets :gb_sets.from_list(@list)
  @gbtrees :gb_trees.from_orddict(@dict)
# -------------------------
# This one is the key metrics

#   bench "rbdict: words from_list", [words: words()] do
#     :rbdict.from_list(words)
#   end

#   bench "gb_sets: words from_list", [words: words()] do
#     :gb_sets.from_list(words)
#   end

#   bench "gb_trees: words from_list", [words: words()] do
#     :gb_trees.from_orddict(words)
#   end

#   bench "Tree: words from_orddict", [words: words()] do
#     Tree.from_orddict(words)
#   end

# # -------------------------


#   bench "rbdict: new from_list" do
#     :rbdict.from_list(@dict)
#   end

#   bench "gb_sets: new from_list" do
#     :gb_sets.from_list(@dict)
#   end

#   bench "gb_trees: new from_list" do
#     :gb_trees.from_orddict(@dict)
#   end

#   bench "Tree: new from_list" do
#     Tree.from_list(@dict)
#   end

# # -------------------------

  bench "Tree: delete", [words: words()] do
      IO.inspect Tree.delete(@tree, "abbe")
  end

  bench "rbdict: delete", [words: words()] do
      :rbdict.erase("abbe",  @rbdict)
  end

  # bench "gbsets: delete", [words: words()] do
  #   :gb_sets.delete(100, @gbsets)
  # end

  bench "gbtrees: delete", [words: words()] do
    for {i, _} <- words do
      :gb_trees.delete_any("abbe" , @gbtrees)
    end
  end

# # -------------------------

#   bench "Tree: to_list" do
#     Tree.to_list(@tree)
#   end

#   bench "rbdict: to_list" do
#     :rbdict.to_list(@rbdict)
#   end

#   bench "gbsets: to_list" do
#     :gb_sets.to_list(@gbsets)
#   end

#   bench "gbtrees: to_list" do
#     :gb_trees.to_list(@gbtrees)
#   end

# # -------------------------

#   bench "Tree: lookup" do
#     for i <- @list do
#       Tree.fetch(@tree, i)
#     end
#   end

#   bench "rbdict: lookup" do
#     for i <- @list do
#       :rbdict.fetch(i, @rbdict)
#     end
#   end

#   bench "gbtrees: lookup" do
#     for i <- @list do
#       :gb_trees.lookup(100, @gbtrees)
#     end
#   end

# # -------------------------

#   bench "Tree: get size" do
#       Tree.size(@tree)
#   end

#   bench "rbdict: get size" do
#     :rbdict.size(@rbdict)
#   end

#   bench "gb_trees: get size" do
#     :gb_trees.size(@gbtrees)
#   end

#   bench "gbsets: get size" do
#     :gb_sets.size(@gbsets)
#   end

# # -------------------------

#   bench "Tree: is_element" do
#     Tree.member?(@tree, 10)
#   end

#   bench "rbdict: is_element" do
#     :rbdict.is_key(10, @rbdict)
#   end

#   bench "gbsets: is_element" do
#     :gb_sets.is_element(10, @gbsets)
#   end

#   bench "gbtrees: is_defined" do
#     :gb_trees.is_defined(10, @gbtrees)
#   end

# -------------------------
  def words do
    {:ok, lines} = File.read "bench/female-names.txt"
    lines |> String.split("\n") |> Enum.map(&{&1, &1})
  end
end