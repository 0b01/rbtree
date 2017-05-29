defmodule Tree do
  @moduledoc """

  A set of functions for red-black tree.

  Red-black tree is a self-balancing binary search tree data structure. Although Elixir has
  excellent support for hash map, it does not include any sorted or ordered data structures.
  This package will be the underlying data structure for SortedMap and SortedSet.
  In addition to usual operations, it also supports ordinal indexing with time
  complexity O(log(N)) for versatility.

  Author: Ricky Han<rickylqhan@gmail.com>
  Modified from Data.Set.RBtree package in Haskell.
  """

  @behaviour Access
# {node, size, comparator}
#--------------------------------------------------------------

  # Attributes
  def null?({node,_}) do
    case node do
      nil -> true
      _ -> false
    end
  end

  def height({nil,_}) do
    0
  end

  def height({{_,h,_,_,_,_},_,_}) do
    h
  end

  def size({_,size}) do
    size
  end

#--------------------------------------------------------------

  # Create
  def new() do
    empty()
  end

  def new(list)
  def new(list) when is_list(list) do
    from_list(list)
  end

  def empty() do
    {nil,0}
  end

  def singleton(key, value \\ nil)
  def singleton(key, value) do
    {{:black, 1, key, value, nil, nil},1}
  end

  def from_list(l, tree_acc \\ {nil, 0})
  def from_list([], tree_acc) do
    tree_acc
  end
  def from_list([h|t]=list, tree_acc) when is_list(list) do
    from_list(t, insert(tree_acc, h, nil))
  end

  def from_orddict(list, tree_acc \\ {nil, 0})
  def from_orddict([], tree_acc) do
    tree_acc
  end
  def from_orddict([{k,v}|t]=list, tree_acc) when is_list(list) do
    from_orddict(t, insert(tree_acc, k, v))
  end

#--------------------------------------------------------------
  def reduce(tree, acc, fun) do
    __MODULE__.to_list(tree)
    |> Enum.reduce(acc, fun)
  end
#--------------------------------------------------------------

  def to_map(tree) do
    tree |> to_list |> Enum.into(%{})
  end

#--------------------------------------------------------------

  def to_list(tree, acc \\ [])
  def to_list({nil,_}, acc) do
    acc
  end
  def to_list({node,_}, acc) do
    do_to_list(node, acc) |> Enum.reverse
  end
  defp do_to_list(nil, acc) do
    acc
  end
  defp do_to_list({_,_,k,nil,l,r}, acc) do
    do_to_list(l, [k | do_to_list(r, acc)])
  end
  defp do_to_list({_,_,k,v,l,r}, acc) do
    do_to_list(l, [ {k,v} | do_to_list(r, acc)])
  end

#--------------------------------------------------------------

  # For Access behavior
  # def fetch(tree, key) do
  #   ret = get(tree, key)
  #   if ret == nil do
  #     :error
  #   else
  #     {:ok, ret}
  #   end
  # end

  def get_and_update(tree, key, fun) do
    {get, update} = fun.(__MODULE__.fetch(tree, key))
    {get, __MODULE__.insert(tree, key, update)}
  end

  def pop(tree, key) do
    value = __MODULE__.get(tree, key, :error)
    new_tree = __MODULE__.delete(tree, key)
    {value, new_tree}
  end

  def get(tree, key, default) do
    case fetch(tree, key) do
      {:ok, val} -> val
      :error -> default
    end
  end

#--------------------------------------------------------------

  def index({{_,_,k,_,l,_},_}, ks) when ks < k do
    index({l,nil}, ks)
  end
  def index({{_,h,k,_,_,r},_}, ks) when ks > k do
    index({r,nil}, ks) + left_count(h) + 1
  end
  def index({{_,h,_,_,_,_},_}, _) do
    left_count(h)
  end

#--------------------------------------------------------------

  def fetch({nil,_}, ks) do nil end
  def fetch({{_,_,k,_,l,_},_}, ks) when ks < k do
    fetch({l,nil}, ks)
  end
  def fetch({{_,_,k,_,_,r},_}, ks) when ks > k do
    fetch({r,nil}, ks)
  end
  def fetch({{_,_,_,v,_,_},_}, _) do
    v
  end

  def set(tree, key, value) do
    insert(tree, key, value)
  end
#--------------------------------------------------------------

  def has_key?(tree, key) do
    member?(tree, key)
  end

  def member?({nil,_}, _search_key) do
    false
  end
  def member?({{_,_,k,_,l,_},_}, srch_key) when srch_key < k do
    member?({l,nil},srch_key)
  end
  def member?({{_,_,k,_,_,r},_}, srch_key) when srch_key > k do
    member?({r,nil},srch_key)
  end
  def member?({{_,_,_,_,_,_},_}, _) do
    true
  end

#--------------------------------------------------------------
# Internals

  defp balanced? n do
    (is_black_same n) && (is_red_separate n)
  end

  defp is_black_same n do
    [h | t] = blacks n
    Enum.all?(t, &(&1 == h) )
  end

  defp blacks(n, acc \\ 0)
  defp blacks(nil, acc) do
    [acc + 1]
  end
  defp blacks({:black,_,_,_,l,r}, acc) do
    [blacks(l, acc + 1) | blacks(r, acc + 1)]
  end
  defp blacks({:red,_,_,_,l,r}, acc) do
    [blacks(l, acc) | blacks(r, acc)]
  end
  defp is_red_separate(t) do
    reds(:black, t)
  end
  defp reds(_color, nil), do: true
  defp reds(:red, {:red,_,_,_,_,_}) do
    false
  end
  defp reds(_color, {c,_,_,_,l,r}) do
    (reds c, l) && (reds c, r)
  end



  defp ordered?(tree)
  defp ordered?(tree) do
    tree |> to_list |> Enum.reverse |> do_ordered()
  end
  defp do_ordered(list)
  defp do_ordered([]), do: true
  defp do_ordered([_]), do: true
  defp do_ordered([x|[y|_]=xs]), do: x<=y && do_ordered(xs)

  defp black_height(nil), do: true
  defp black_height({:black,h,_,_,_,_}=t) do
    do_black_height(t, h)
  end
  defp black_height(_) do
    {:error, "black_height"}
  end
  defp do_black_height(nil, h) do
    h == 0
  end
  defp do_black_height({:red,nh,_,_,l,r}, h) do
    (h == nh - 1) && do_black_height(l, h) && do_black_height(r, h)
  end
  defp do_black_height({:black,nh,_,_,l,r}, h) do
    (h == nh) && do_black_height(l, h - 1) && do_black_height(r, h - 1)
  end

  defp turn_red({_,h,k,v,l,r}) do
    {:red,h,k,v,l,r}
  end
  defp turn_black({_,h,k,v,l,r}) do
    {:black,h,k,v,l,r}
  end
  defp do_turn_black(nil) do
    nil
  end
  defp do_turn_black(node) do
    turn_black(node)
  end

#--------------------------------------------------------------

  def minimum({_,_,k,v,nil,_}) do
    {k, v}
  end
  def minimum({_,_,_,_,l,_}) do
    minimum(l)
  end

  def maximum({_,_,k,v,_,nil}) do
    {k, v}
  end
  def maximum({_,_,_,_,_,r}) do
    maximum(r)
  end

#--------------------------------------------------------------

  def range({_,size}, a, b) when a > size - 1
                              or b > size - 1 do
    nil
  end
  def range({_,_}=tree, a, b) when a == b do
    [nth(tree, a)]
  end
  def range({r,size}, a, b) when a < 0 and b < 0 do
    do_range(r, size + a, size + b)
  end
  def range({r,size}, a, b) when a < 0 and b >= 0 and b - (size + a) > 0 do
    do_range(r, size + a, b)
  end
  def range({_,size}=tree, a, b) when a < 0 and b >= 0 and b - (size + a) == 0 do
    [nth(tree, b)]
  end
  def range({r,size}, a, 0) when a < 0 do
    do_range(r, size + a, size - 1)
  end
  def range({r,size}, a, b) when a >= 0 and b < 0 do
    do_range(r, a, size + b)
  end
  def range({_,_}, a, b) when a > b do
    nil
  end
  def range({r,_}, a, b) when a >= 0 and b >= 0 do
    do_range(r, a, b)
  end

  defp do_range({_,h,k,v,l,r}, a, b) do
    lc = left_count(h)
    cond do
      a == b && a == lc ->
        [{k,v}]
      a < lc && b < lc ->
        do_range(l, a, b)
      a > lc && b > lc ->
        do_range(r, a-lc-1, b-lc-1)
      a < lc && b > lc ->
        do_range(l, a, lc - 1) ++ [{k,v} | do_range(r, 0, b-lc-1)]
      a == lc && b > lc ->
        [{k,v} | do_range(r, 0, b-lc-1)]
      a < lc && b == lc ->
        do_range(l, a, b-1) ++ [{k,v}]
    end
  end

#--------------------------------------------------------------

  def nth({_,0}, _n) do
    nil
  end
  def nth({_,size}, n) when n > size - 1 do
    nil
  end
  def nth({r,size}, n) when n < 0 do
    do_nth(r, size + n)
  end
  def nth({r,_}, n) when n >= 0 do
    do_nth(r, n)
  end

  defp do_nth({_,h,k,v,l,r}, n) do
    l_count = left_count(h)
    cond do
      l_count > n && l == nil -> {k,v}
      l_count > n -> do_nth(l, n)
      l_count == n -> {k,v}
      r == nil -> {k,v}
      true -> do_nth(r, n - l_count - 1)
    end
  end

  defp left_count(1) do
    0
  end
  defp left_count(0) do
    0
  end
  defp left_count(h) do
    :math.pow(2,h-1)-1 |> round
  end

#--------------------------------------------------------------
  # filter range by value

  def filter_range_by_value(tree, min, max, l_inc \\ true, r_inc \\ true) do
    to_list(tree) |> Enum.filter(fn {_,v} ->
         ((l_inc && v >= min) || (!l_inc && v > min))
      && ((r_inc && v <= max) || (!r_inc && v < max))
    end)
  end

#--------------------------------------------------------------
  # filter range

  def filter_range({node,_}, min, max, l_inc \\ true, r_inc \\ true) do
    do_filter_range(node, min, max, l_inc, r_inc) |> Enum.map(fn {a,b} -> if b == nil do a else {a,b} end end)
  end

  defp do_filter_range(nil, _min, _max, l_inc, r_inc) do
    []
  end

  defp do_filter_range({_,_,k,v,_,_}, min, max, l_inc, r_inc) when max == min and min == k do
    [{k,v}]
  end

  defp do_filter_range({_,_,k,v,l,r}, min, max, l_inc, r_inc)
    when ((l_inc and k >= min) or (not l_inc and k > min))
     and ((r_inc and k <= max) or (not r_inc and k < max)) do
    do_filter_range(l, min, max, l_inc, r_inc) ++ [{k,v} | do_filter_range(r, min, max, l_inc, r_inc)]
  end

  defp do_filter_range({_,_,k,_,_,r}, min, max, l_inc, r_inc) when k < min do
    do_filter_range(r, min, max, l_inc, r_inc)
  end

  defp do_filter_range({_,_,_,_,l,_}, min, max, l_inc, r_inc) do
    do_filter_range(l, min, max, l_inc, r_inc)
  end

#--------------------------------------------------------------
  # to_string

  def to_string({tree,size}) do
    "\n(size:" <> Integer.to_string(size) <> ")\n" <> do_to_string "", tree
  end
  def do_to_string(_, nil) do
    "\n"
  end
  def do_to_string(pref, {c,h,k,v,l,r}) do
       Atom.to_string(c) <> " { " <> Kernel.inspect(k) <> ", " <> Kernel.inspect(v) <> " }(d:"
       <> Integer.to_string(h) <> ")\n"
    <> pref <> "+ " <> do_to_string(("  " <> pref), l)
    <> pref <> "+ " <> do_to_string(("  " <> pref), r)
  end

#--------------------------------------------------------------

#--------------------------------------------------------------

  def valid? tree do
    balanced?(tree) && black_height(tree) && ordered?(tree)
  end

#--------------------------------------------------------------
  ## Basic Operations
#--------------------------------------------------------------
  ## Insertion
  #  Chris Okasaki

  # def insert(tree, k) do insert(tree, k, nil) end
  def insert({node,size}, k, v) do
    {new_node, status} = do_insert(node, k, v)
    {_,h,k,v,l,r} = new_node
    new_node = {:black,h,k,v,l,r}
    new_size = if status == :add do size + 1 else size end # todo: might be slowing op down
    {new_node, new_size}
  end

  defp do_insert(nil, key, val) do
    {{:red, 1, key, val, nil, nil}, :add}
  end

  defp do_insert({:black,h,k,v,l,r}, kx, vx) when kx == k do
    status = if v == vx do :replace else :add end
    {{:black,h,kx,vx,l,r}, status}
  end

  defp do_insert({:black,h,k,v,l,r}, kx, vx) when kx < k do
    {node, status} = do_insert(l, kx, vx)
    {do_balance_left(h, node, k, r, v), status}
  end

  defp do_insert({:black,h,k,v,l,r}, kx, vx) when kx > k do
    {node, status} = do_insert(r, kx, vx)
    {do_balance_right(h, l, k, node, v), status}
  end

  defp do_insert({:red,h,k,v,l,r}, kx, vx) when kx == k do
    status = if v == vx do :replace else :add end
    {{:red,h,kx,vx,l,r}, status}
  end

  defp do_insert({:red,h,k,v,l,r}, kx, vx) when kx < k do
    {node, status} = do_insert(l, kx, vx)
    {{:red, h, k, v, node, r}, status}
  end

  defp do_insert({:red,h,k,v,l,r}, kx, vx) when kx > k do
    {node, status} = do_insert(r, kx, vx)
    {{:red, h, k, v, l, node}, status}
  end

  defp do_balance_left(h, {:red,_,y,yv,{:red,_,x,xv,a,b},c}, z, d, zv) do
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,h,z,zv,c,d}}
  end

  defp do_balance_left(h, {:red,_,x,xv,a,{:red,_,y,yv,b,c}},z ,d, zv) do
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,h,z,zv,c,d}}
  end

  defp do_balance_left(h, l, x, r, xv) do
    {:black,h,x,xv,l,r}
  end

  defp do_balance_right(h, a, x, {:red,_,z,zv,{:red,_,y,yv,b,c},d},xv) do
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,h,z,zv,c,d}}
  end

  defp do_balance_right(h, a, x, {:red,_,y,yv,b,{:red,_,z,zv,c,d}}, xv) do
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,h,z,zv,c,d}}
  end

  defp do_balance_right(h, l, x, r, xv) do
    {:black,h,x,xv,l,r}
  end

  # # PEG.js parser
  # Start
  #   = TypeNode
  # TypeNode
  #   = "TypeNode" _ c:Color _ d:Atom _ l:TypeNode _ v:Atom _ r:TypeNode
  #     { return `{${c}, ${d}, ${v}, _, ${l}, ${r}}` }
  #   / "("node:TypeNode")" {return node;}
  #   / Atom
  # Color
  #   = color:[BR] {return color === "B" ? "color: :black" : "color: :red";}
  # Atom
  #   = atom:[0-9a-zA-Z+-_]+ {return atom;}
  #   / "("a:Atom")" {return a;}
  # _ "whitespace"
  #   = [ \t\n\r]*

#--------------------------------------------------------------

  defp balance_left(:black, h, {:red,_,y,yv,{:red,_,x,xv,a,b},c}, z, v, d) do
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,h,z,v,c,d,}}
  end
  defp balance_left(:black, h, {:red,_,x,xv,a,{:red,_,y,yv,b,c}}, z, v, d) do
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,z,v,c,d}}
  end
  defp balance_left(k, h, l, x, v, r) do
    {k,h,x,v,l,r}
  end

  defp balance_right(:black, h, a, x, v, {:red,_,y,yv,b,{:red,_,z,zv,c,d}}) do
    {:red,h+1,y,yv,{:black,h,x,v,a,b},{:black,h,z,zv,c,d}}
  end
  defp balance_right(:black, h, a, x, v, {:red,_,z,zv,{:red,_,y,yv,b,c},d}) do
    {:red,h+1,y,yv,{:black,h,x,v,a,b},{:black,h,z,zv,c,d}}
  end
  defp balance_right(k, h, l, x, v, r) do
    {k,h,x,v,l,r}
  end

# ----------------------------------------------------------------

  defp unbalanced_left(c, h, {:black,_,_,_,_,_}=l, x, v, r) do
    {balance_left(:black, h, (turn_red l), x, v, r), (c == :black)}
  end
  defp unbalanced_left(:black, h, {:red,lh,lx,lxv,ll,{:black,_,_,_,_,_}=lr}, x, v, r) do
    {{:black,lh,lx,lxv,ll,balance_left(:black, h, turn_red(lr), x, v, r)}, false}
  end
  defp unbalanced_right(c, h ,l, x, v,{:black,_,_,_,_,_}=r) do
    {balance_right(:black, h, l, x, v, turn_red(r)), c == :black}
  end
  defp unbalanced_right(:black, h, l, x, v, {:red,rh,rx,rxv,{:black,_,_,_,_,_,_}=rl,rr}) do
    {{:black,rh,rx,rxv,balance_right(:black, h, l, x, v, turn_red(rl)),rr}, false}
  end

# ----------------------------------------------------------------

  def delete_min({nil,_}) do
    empty()
  end
  def delete_min({t,size}) do
    {{s, _}, _} = do_delete_min t
    {do_turn_black(s),size - 1}
  end

  defp do_delete_min(nil) do
    throw("error")
  end
  defp do_delete_min({:black,_,x,v,nil,nil}) do
    {{nil, true}, {x,v}}
  end
  defp do_delete_min({:black,_,x,v,nil,{:red,_,_,_,_,_}=r}) do
    {{turn_black(r), false}, {x,v}}
  end
  defp do_delete_min({:red,_,x,v,nil,r}) do
    {{r, false}, {x,v}}
  end
  defp do_delete_min({c,h,x,v,l,r}) do
    {{do_l, d}, m} = do_delete_min l
    tD = unbalanced_right(c, (h-1), do_l, x, v, r)
    do_tD = {{c,h,x,v,do_l,r}, false}
    if d do {tD, m} else {do_tD, m} end
  end

# ----------------------------------------------------------------

  def delete_max({nil,_,_}) do
    empty()
  end
  def delete_max({t,size}) do
    {{s, _},_} = do_delete_max t
    {do_turn_black(s), size - 1}
  end

  defp do_delete_max(nil) do
    throw("do_delete_max")
  end
  defp do_delete_max({{:black,_,x,_,nil,nil}}) do
    {{nil, true}, x}
  end
  defp do_delete_max({:black,_,x,_,{:red,_,_,_,_,_}=l,nil}) do
    {{turn_black(l), false}, x}
  end
  defp do_delete_max({:red,_,x,_,l,nil}) do
    {{l, false}, x}
  end
  defp do_delete_max({c,h,x,v,l,r}) do
    {{do_r, d}, m} = do_delete_max r
    tD  = unbalanced_left(c, (h-1), l, x, v, do_r)
    do_tD = {{c,h,x,v,l,do_r}, false}
    if d do {tD, m} else {do_tD, m} end
  end

# ----------------------------------------------------------------

  defp blackify({:red,_,_,_,_,_}=s) do
    {turn_black(s), false}
  end
  defp blackify(s) do
    {s, true}
  end

# ----------------------------------------------------------------

  def delete({t,size}, x) do
    {s, bool} = do_delete(x, t)
    new_size = if bool do size else size - 1 end
    {do_turn_black(s), new_size}
  end

  defp do_delete(_, nil) do
    {nil, false}
  end

  defp do_delete(x, {c,h,y,yv,l,r}) when x < y do
    {do_l, d} = do_delete(x,l)
    t = {c,h,y,yv,do_l,r}
    if d do unbalanced_right(c, h-1, do_l, y, yv, r) else {t, false} end
  end

  defp do_delete(x, {c,h,y,yv,l,r}) when x > y do
    {do_r, d} = do_delete(x,r)
    t = {c,h,y,yv,l,do_r}
    if d do unbalanced_left(c, h-1, l, y, yv, do_r) else {t, false} end
  end

  defp do_delete(x, {c,_h,y,_yv,l,nil}) when x == y do
    if c == :black do blackify l else {l, false} end
  end

  defp do_delete(x, {c,h,y,_yv,l,r}) when x == y do
    {{do_r, d}, {m,v}} = do_delete_min r
    t = {c,h,m,v,l,do_r}
    if d do unbalanced_left(c, h-1, l, m, v, do_r) else {t, false} end
  end

# ----------------------------------------------------------------

# ----------------------------------------------------------------
# -- Set operations
# ----------------------------------------------------------------

  def join(nil, k, t2) do
    insert(k, t2, nil)
  end
  def join(t1, k, nil) do
    insert(k, t1, nil)
  end
  def join(t1, k, t2) do
    h1 = height t1
    h2 = height t2
    cond do
      h1 == h2 ->
        {:black,h1+1,k,nil,t1,t2} # value is nil for now
      h1 < h2 ->
        turn_black(join_lt(t1, k, t2, h1))
      h1 > h2 ->
        turn_black(join_gt(t1, k, t2, h2))
    end
  end

  defp join_lt(t1, k, {c,h,x,v,l,r}=t2, h1) do
    if h == h1 do
      {:red,h+1,k,nil,t1,t2} # value is nil for now
    else
      balance_left(c, h, (join_lt(t1, k, l, h1)), x, v, r)
    end
  end

  defp join_gt({c,h,x,v,l,r}=t1, k, t2, h2) do
    if h == h2 do
      {:red,h+1,k,nil,t1,t2} # value is nil for now
    else
      balance_right(c, h, l, x, v, (join_gt(r, k, t2, h2)))
    end
  end


# ----------------------------------------------------------------

  def merge(nil, t2) do
    t2
  end
  def merge(t1, nil) do
    t1
  end
  def merge(t1, t2) do
    h1 = height t1
    h2 = height t2
    cond do
      h1 < h2 -> turn_black(merge_lt(t1, t2, h1))
      h1 == h2 -> turn_black(merge_gt(t1, t2, h2))
      h1 > h2 -> turn_black(merge_eq(t1, t2))
    end
  end

  defp merge_lt(t1,{c,h,x,v,l,r}=t2, h1) do
    if h == h1 do
      merge_eq t1, t2
    else
      balance_left(c, h, (merge_lt(t1, l, h1)), x, v, r)
    end
  end

  defp merge_gt({c,h,x,v,l,r}=t1,
   t2, h2) do
    if h == h2 do
      merge_eq t1, t2
    else
      balance_right(c, h, l, x, v, (merge_gt(r, t2, h2)))
    end
  end

  defp merge_eq(nil, nil) do
    nil
  end
  defp merge_eq({_,h,x,v,l,r}=t1, t2) do
    {mk,mv}  = minimum t2
    do_t2 = delete_min t2
    do_h2 = height do_t2
    {:red,_,rx,rxv,rl,rr} = r
    cond do
      h == do_h2 ->
        {:red,h+1,mk,mv,t1,do_t2}
      is_red l   ->
        {:red,h+1,x,v,turn_black(l),{:black,h,mk,mv,r,do_t2}}
      is_red r   ->
        {:black,h,rx,rxv,{:red,h,x,v,l,rl},{:red,h,mk,mv,rr,do_t2}}
      true       ->
        {:black,h,mk,mv,turn_red(t1),do_t2}
    end
  end

  defp is_red({:red,_,_,_,_,_}) do
    true
  end
  defp is_red(_) do
    false
  end


# ----------------------------------------------------------------

  def split(_, nil) do
    {nil, nil}
  end
  def split(kx, {_,_,k,_,l,r}) do
    cond do
      kx < k ->
        {lt, gt} = split(kx, l)
        {lt, join(gt, k, r |> turn_black)}
      kx > k ->
        {lt, gt} = split(kx, r)
        {join((l |> turn_black), k, lt), gt}
      kx == k ->
        {l |> turn_black, r |> turn_black}
    end
  end

# ----------------------------------------------------------------

  def union(t1, nil) do
    t1
  end
  def union(nil, t2) do
    turn_black(t2)
  end
  def union(t1, {_,_,k,_,l,r}) do
    {do_l, do_r} = split(k, t1)
    join((union do_l, l), k, (union do_r, r))
  end

# ----------------------------------------------------------------

  def intersection(nil, _) do
    nil
  end
  def intersection(_, nil) do
    nil
  end
  def intersection(t1, {_,_,k,_,l,r}) do
    {do_l, do_r} = split(k, t1)
    if (member?(k, t1)) do
      join((intersection do_l, l), k, (intersection do_r, r))
    else
      merge((intersection do_l, l), (intersection do_r, r))
    end
  end

# ----------------------------------------------------------------

  def difference(nil, _) do
    nil
  end
  def difference(t1, nil) do
    t1
  end
  def difference(t1, {_,_,k,_,l,r}) do
    {do_l, do_r} = split k, t1
    merge((difference(do_l, l)), (difference(do_r, r)))
  end

# ----------------------------------------------------------------


  def reduce_nodes({_,_,_}=tree, acc, fun) do
    reduce_nodes(:in_order, tree, acc, fun)
  end

  def reduce_nodes(_order, {nil,_,_}, acc, _fun) do
    acc
  end

  def reduce_nodes(order, {root,_,_}, acc, fun) do
    do_reduce_nodes(order, root, acc, fun)
  end

  defp do_reduce_nodes(_order, nil, acc, _fun) do
    acc
  end

  # self, left, right
  defp do_reduce_nodes(:pre_order, {_,_,_,_,l,r}=node, acc, fun) do
    acc_after_self = fun.(node, acc)
    acc_after_left = do_reduce_nodes(:pre_order, l, acc_after_self, fun)
    do_reduce_nodes(:pre_order, r, acc_after_left, fun)
  end

  # left, self, right
  defp do_reduce_nodes(:in_order, {_,_,_,_,l,r}=node, acc, fun) do
    acc_after_left = do_reduce_nodes(:in_order, l, acc, fun)
    acc_after_self = fun.(node, acc_after_left)
    do_reduce_nodes(:in_order, r, acc_after_self, fun)
  end

  # left, right, self
  defp do_reduce_nodes(:post_order, {_,_,_,_,l,r}=node, acc, fun) do
    acc_after_left = do_reduce_nodes(:post_order, l, acc, fun)
    acc_after_right = do_reduce_nodes(:post_order, r, acc_after_left, fun)
    fun.(node, acc_after_right)
  end


# ----------------------------------------------------------------
  # Comparator
  def comparator(term1, term2) do
    cond do
      term1 == term2 -> 0
      term1 < term2 -> -1
      term1 > term2 -> 1
    end
  end
  # def compare_items(term1, term2) do
  #   cond do
  #     term1 === term2 -> 0
  #     term1 < term2 -> -1
  #     term1 > term2 -> 1
  #     term1 == term2 ->
  #       case compare_items(hash_term(term1), hash_term(term2)) do
  #         0 -> compare_items(fallback_term_hash(term1),
  #           fallback_term_hash(term2))
  #         hash_comparison_result -> hash_comparison_result
  #       end
  #   end
  # end

  # defp hash_term(term) do
  #   :erlang.phash2(term, @key_hash_bucket)
  # end

  # defp fallback_term_hash(term) do
  #   :erlang.phash(term, @key_hash_bucket)
  # end

end


# defimpl Enumerable, for: Tree do
#   def count({_,size,_}) do size end
#   def member?({_,_,_}=tree, key) do Tree.has_key?(tree, key) end
#   def reduce(tree, acc, fun) do Tree.reduce(tree, acc, fun) end
# end

# defimpl Collectable, for: Tree do
#   def into(original) do
#     {original, fn
#       tree, {:cont, {key, value}} -> Tree.insert(tree, key, value)
#       tree, :done -> tree
#       _, :halt -> :ok
#     end}
#   end
# end

# defimpl Inspect, for: Tree do
#   import Inspect.Algebra
#   def inspect(tree, opts) do
#     concat ["#Tree<", Inspect.List.inspect(Tree.to_list(tree), opts), ">"]
#   end
# end
