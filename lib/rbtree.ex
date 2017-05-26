defmodule Rbtree do
  @moduledoc """
    Author: Ricky Han<rickylqhan@gmail.com>
    Based on Haskell Data.Set.RBtree implementation
    https://hackage.haskell.org/package/llrbtree-0.1.1/docs/src/Data-Set-RBTree.html

    {color, depth, key, value, left, right}
  """
  @behaviour Access
  @key_hash_bucket 4294967296

  defstruct(
    size: 0,
    node: nil,
    comparator: &__MODULE__.compare_items/2
  )

#--------------------------------------------------------------

  # Attributes
  def null?(%Rbtree{node: node}) do
    case node do
      nil -> true
      _ -> false
    end
  end

  def height(%Rbtree{node: nil}), do: 0
  def height(%Rbtree{node: {_,h,_,_,_,_}}), do: h

  def size(%Rbtree{size: size}), do: size

#--------------------------------------------------------------

  # Create
  def new(), do: empty()
  def new(list, comparator \\ &compare_items/2)
  def new(list, comparator) when is_list(list), do: from_list(list, comparator)

  def empty(cp \\ &compare_items/2) do
    %Rbtree{node: nil, comparator: cp}
  end

  def singleton(key), do:
    singleton(key, nil)

  def singleton(key, value), do:
    %Rbtree{node: {:black, 1, key, value, nil, nil}}


  def from_list(list, comparator \\ &compare_items/2) when is_list(list) do
    Enum.reduce(list, empty(comparator), fn(i, set) ->
      case i do
        {k, v} ->
          insert(set, k, v)
         k ->
          insert(set, k)
      end
    end)
  end

#--------------------------------------------------------------
  def reduce(tree, acc, fun) do
    Rbtree.to_list(tree)
    |> Enum.reduce(acc, fun)
  end
#--------------------------------------------------------------

  def to_map(tree) do
    tree |> to_list |> Enum.into(%{})
  end

#--------------------------------------------------------------

  def to_list(tree, acc \\ [])
  def to_list(%Rbtree{node: nil}, acc), do: acc
  def to_list(%Rbtree{node: node}, acc), do: do_to_list(node, acc)
  defp do_to_list(nil, acc), do: acc
  defp do_to_list({_,_,k,v,l,r}, acc) when v == nil, do:
    do_to_list(l, do_to_list(r, acc) ++ [k])
  defp do_to_list({_,_,k,v,l,r}, acc), do:
    do_to_list(l, do_to_list(r, acc) ++ [{k,v}])

#--------------------------------------------------------------

  # For Access behavior
  def fetch(tree, key) do
    ret = get(tree, key)
    if ret == nil do
      :error
    else
      {:ok, ret}
    end
  end

  def get_and_update(tree, key, fun) do
    {get, update} = fun.(Rbtree.get(tree, key))
    {get, Rbtree.insert(tree, key, update)}
  end

  def pop(tree, key) do
    value = Rbtree.get(tree, key, :error)
    new_tree = Rbtree.delete(tree, key)
    {value, new_tree}
  end

  def get(tree, key, default) do
    case fetch(tree, key) do
      {:ok, val} -> val
      :error -> default
    end
  end

#--------------------------------------------------------------

  def get(%Rbtree{node: nil}, _key), do: nil
  def get(%Rbtree{node: node, comparator: cp}, key), do:
    do_get(node, key, cp)
  defp do_get(nil, _search_key, _comparator), do: false
  defp do_get({_,_,k,v,l,r}, srch_key, cp) do
    case cp.(srch_key, k) do
       0 -> v
      -1 -> do_get(l, srch_key, cp)
       1 -> do_get(r, srch_key, cp)
    end
  end

  def set(tree, key, value), do:
    insert(tree, key, value)
#--------------------------------------------------------------

  def has_key?(tree, key), do: member?(tree, key)

  def member?(%Rbtree{node: nil}, _key), do: false
  def member?(%Rbtree{node: node, comparator: cp}, key), do:
    do_member?(node, key, cp)

  defp do_member?(nil, _search_key, _comparator), do: false
  defp do_member?({_,_,k,_,l,r}, srch_key, cp) do
    case cp.(srch_key, k) do
       0 -> true
      -1 -> do_member?(l, srch_key, cp)
       1 -> do_member?(r, srch_key, cp)
    end
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
  defp blacks(nil, acc), do: [acc + 1]

  defp blacks({:black,_,_,_,l,r}, acc), do:
    blacks(l, acc + 1) ++ blacks(r, acc + 1)

  defp blacks({:red,_,_,_,l,r}, acc), do:
    blacks(l, acc    ) ++ blacks(r, acc    )

  defp is_red_separate(t), do: reds(:black, t)

  defp reds(_color, nil), do: true
  defp reds(:red, {:red,_,_,_,_,_}), do: false
  defp reds(_color, {c,_,_,_,l,r}), do:
    (reds c, l) && (reds c, r)

  defp ordered?(tree, comparator \\ &compare_items/2)
  defp ordered?(tree, cp), do: tree |> to_list |> Enum.reverse |> do_ordered(cp)
  defp do_ordered(list, cp \\ &compare_items/2)
  defp do_ordered([], _), do: true
  defp do_ordered([_], _), do: true
  defp do_ordered([x|[y|_]=xs], cp), do: cp.(x,y) && do_ordered(xs)

  defp black_height(nil), do: true
  defp black_height({:black,h,_,_,_,_}=t), do: do_black_height(t, h)
  defp black_height(_), do: {:error, "black_height"}
  defp do_black_height(nil, h), do: h == 0
  defp do_black_height({:red,nh,_,_,l,r}, h), do:
    (h == nh - 1) && do_black_height(l, h) && do_black_height(r, h)
  defp do_black_height({:black,nh,_,_,l,r}, h), do:
    (h == nh) && do_black_height(l, h - 1) && do_black_height(r, h - 1)

  defp turn_red({_,h,k,v,l,r}), do: {:red,h,k,v,l,r}
  defp turn_black({_,h,k,v,l,r}), do: {:black,h,k,v,l,r}
  defp do_turn_black(nil), do: nil
  defp do_turn_black(node), do: turn_black(node)

#--------------------------------------------------------------

  def minimum({_,_,k,v,nil,_}), do: {k, v}
  def minimum({_,_,_,_,l,_}), do: minimum(l)

  def maximum({_,_,k,v,_,nil}), do: {k, v}
  def maximum({_,_,_,_,_,r}), do: maximum(r)

#--------------------------------------------------------------

  def range(%Rbtree{size: size}, a..b) when a > size - 1
                                         or b > size - 1, do: nil
  def range(%Rbtree{}=tree, a..b) when a == b, do: [nth(tree, a)]
  def range(%Rbtree{node: r, size: size}, a..b)
    when a < 0 and b < 0, do:
      do_range(r, size + a, size + b)
  def range(%Rbtree{node: r, size: size}, a..b)
    when a < 0 and b >= 0 and b - (size + a) > 0, do:
      do_range(r, size + a, b)
  def range(%Rbtree{size: size}=tree, a..b)
    when a < 0 and b >= 0 and b - (size + a) == 0, do:
      [nth(tree, b)]
  def range(%Rbtree{node: r, size: size}, a..b)
    when a < 0 and b == 0, do:
      do_range(r, size + a, size - 1)
  def range(%Rbtree{node: r, size: size}, a..b)
    when a >= 0 and b < 0, do:
      do_range(r, a, size + b)
  def range(%Rbtree{node: r}, a..b)
    when a >= 0 and b >= 0, do: do_range(r, a, b)

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
        do_range(l, a, lc - 1) ++ [{k,v}] ++ do_range(r, 0, b-lc-1)
      a == lc && b > lc ->
        [{k,v}] ++ do_range(r, 0, b-lc-1)
      a < lc && b == lc ->
        do_range(l, a, 0) ++ [{k,v}]
    end
  end

#--------------------------------------------------------------

  def nth(%Rbtree{size: size}, n) when n > size - 1 or size == 0, do: nil
  def nth(%Rbtree{node: r, size: size}, n) when n < 0, do: do_nth(r, size + n)
  def nth(%Rbtree{node: r}, n) when n >= 0, do: do_nth(r, n)
  defp do_nth({_,h,k,v,l,r}, n) do
    l_count = left_count(h)
    cond do
      l_count > n ->
        case l do
          nil -> {k,v}
          _ -> do_nth(l, n)
        end
      l_count == n -> {k,v}
      true ->
        case r do
          nil -> {k,v}
          _ -> do_nth(r, n - l_count - 1)
        end
    end
  end
  defp left_count(1), do: 0
  defp left_count(0), do: 0
  defp left_count(h), do: :math.pow(2,h-1)-1 |> round

#--------------------------------------------------------------
  # filter range

  def filter_range(%Rbtree{node: node, comparator: cp}, min, max), do:
    do_filter_range(node, min, max, cp) |> from_list |> to_list |> Enum.reverse
  defp do_filter_range(nil, _min, _max, _cp), do: []
  defp do_filter_range({_,_,k,v,l,r}, min, max, cp) do
    cond do
      max == k && min == k -> [{k,v}]
      cp.(k, max) <= 0 && cp.(k, min) >= 0 ->
        [{k,v}] ++ do_filter_range(l, min, max, cp) ++
          do_filter_range(r, min, max, cp)
      cp.(k,min) < 0 ->
        do_filter_range(r, min, max, cp)
      true ->
        do_filter_range(l, min, max, cp)
    end
  end

#--------------------------------------------------------------
  # to_string

  def to_string(%Rbtree{node: tree, size: size}) , do: "\n(size:" <> Integer.to_string(size) <> ")\n" <> do_to_string "", tree
  def do_to_string(_, nil), do: "\n"
  def do_to_string(pref, {c,h,k,v,l,r}), do:
       Atom.to_string(c) <> " { " <> Kernel.inspect(k) <> ", " <> Kernel.inspect(v) <> " }(d:"
       <> Integer.to_string(h) <> ")\n"
    <> pref <> "+ " <> do_to_string(("  " <> pref), l)
    <> pref <> "+ " <> do_to_string(("  " <> pref), r)

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

  def insert(tree, k), do: insert(tree, k, nil)
  def insert(%Rbtree{node: node, comparator: cp, size: size}, k, v) do
    new_size = if do_member?(node, k, cp) do size else size + 1 end
    %Rbtree{size: new_size, node: turn_black(do_insert(node, k, v, cp))}
  end

  defp do_insert(nil, key, val, _cp), do:
    {:red, 1, key, val, nil, nil}
  defp do_insert({:black,h,k,v,l,r}, kx, vx, cp) do
    case cp.(kx, k) do
       0 -> {:black,h,kx,vx,l,r}
      -1 -> do_balance_left(h, do_insert(l, kx, vx, cp), k, r, v)
       1 -> do_balance_right(h, l, k, do_insert(r, kx, vx, cp), v)
    end
  end
  defp do_insert({:red,h,k,v,l,r}, kx, vx, cp) do
    case cp.(kx, k) do
       0 -> {:red,h,kx,vx,l,r}
      -1 -> {:red, h, k, v, do_insert(l, kx, vx, cp), r}
       1 -> {:red, h, k, v, l, do_insert(r, kx, vx, cp)}
    end
  end

  defp do_balance_left(h, {:red,_,y,yv,{:red,_,x,xv,a,b},c}, z, d, zv), do:
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,h,z,zv,c,d}}

  defp do_balance_left(h, {:red,_,x,xv,a,{:red,_,y,yv,b,c}},z ,d, zv), do:
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,h,z,zv,c,d}}

  defp do_balance_left(h, l, x, r, xv), do:
    {:black,h,x,xv,l,r}

  defp do_balance_right(h, a, x, {:red,_,y,yv,b,{:red,_,z,zv,c,d}}, xv), do:
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,h,z,zv,c,d}}

  defp do_balance_right(h, a, x, {:red,_,z,zv,{:red,_,y,yv,b,c},d},xv), do:
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,h,z,zv,c,d}}

  defp do_balance_right(h, l, x, r, xv), do:
    {:black,h,x,xv,l,r}

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

  defp balance_left(:black, h, {:red,_,y,yv,{:red,_,x,xv,a,b},c}, z, v, d), do:
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,h,z,v,c,d,}}
  defp balance_left(:black, h, {:red,_,x,xv,a,{:red,_,y,yv,b,c}}, z, v, d), do:
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,z,v,c,d}}
  defp balance_left(k, h, l, x, v, r), do:
    {k,h,x,v,l,r}

  defp balance_right(:black, h, a, x, v, {:red,_,y,yv,b,{:red,_,z,zv,c,d}}), do:
    {:red,h+1,y,yv,{:black,h,x,v,a,b},{:black,h,z,zv,c,d}}
  defp balance_right(:black, h, a, x, v, {:red,_,z,zv,{:red,_,y,yv,b,c},d}), do:
    {:red,h+1,y,yv,{:black,h,x,v,a,b},{:black,h,z,zv,c,d}}
  defp balance_right(k, h, l, x, v, r), do:
    {k,h,x,v,l,r}

# ----------------------------------------------------------------

  defp unbalanced_left(c, h, {:black,_,_,_,_,_}=l, x, v, r), do:
    {balance_left(:black, h, (turn_red l), x, v, r), (c == :black)}
  defp unbalanced_left(:black, h, {:red,lh,lx,lxv,ll,{:black,_,_,_,_,_}=lr}, x, v, r), do:
    {{:black,lh,lx,lxv,ll,balance_left(:black, h, turn_red(lr), x, v, r)}, false}
  defp unbalanced_right(c, h ,l, x, v,{:black,_,_,_,_,_}=r), do:
    {balance_right(:black, h, l, x, v, turn_red(r)), c == :black}
  defp unbalanced_right(:black, h, l, x, v, {:red,rh,rx,rxv,{:black,_,_,_,_,_,_}=rl,rr}), do:
    {{:black,rh,rx,rxv,balance_right(:black, h, l, x, v, turn_red(rl)),rr}, false}

# ----------------------------------------------------------------

  def delete_min(%Rbtree{node: nil}), do: empty()
  def delete_min(%Rbtree{node: t, size: size}) do
    {{s, _}, _} = do_delete_min t
    %Rbtree{node: do_turn_black(s), size: size - 1}
  end

  defp do_delete_min(nil), do: throw("error")
  defp do_delete_min({:black,_,x,v,nil,nil}), do:
    {{nil, true}, {x,v}}
  defp do_delete_min({:black,_,x,v,nil,{:red,_,_,_,_,_}=r}), do:
    {{turn_black(r), false}, {x,v}}
  defp do_delete_min({:red,_,x,v,nil,r}), do:
    {{r, false}, {x,v}}
  defp do_delete_min({c,h,x,v,l,r}) do
    {{do_l, d}, m} = do_delete_min l
    tD = unbalanced_right(c, (h-1), do_l, x, v, r)
    do_tD = {{c,h,x,v,do_l,r}, false}
    if d do
      {tD, m}
    else
      {do_tD, m}
    end
  end

# ----------------------------------------------------------------

  def delete_max(%Rbtree{node: nil}), do: empty()
  def delete_max(%Rbtree{node: t, size: size}) do
    {{s, _},_} = do_delete_max t
    %Rbtree{node: do_turn_black(s), size: size - 1}
  end

  defp do_delete_max(nil), do: throw("do_delete_max")
  defp do_delete_max({{:black,_,x,_,nil,nil}}), do:
    {{nil, true}, x}
  defp do_delete_max({:black,_,x,_,{:red,_,_,_,_,_}=l,nil}), do:
    {{turn_black(l), false}, x}
  defp do_delete_max({:red,_,x,_,l,nil}), do:
    {{l, false}, x}
  defp do_delete_max({c,h,x,v,l,r}) do
    {{do_r, d}, m} = do_delete_max r
    tD  = unbalanced_left(c, (h-1), l, x, v, do_r)
    do_tD = {{c,h,x,v,l,do_r}, false}
    if d do {tD, m} else {do_tD, m} end
  end

# ----------------------------------------------------------------

  defp blackify({:red,_,_,_,_,_}=s), do: {turn_black(s), false}
  defp blackify(s), do: {s, true}

# ----------------------------------------------------------------

  def delete(%Rbtree{node: t, comparator: cp, size: size}, x) do
    {s, _} = do_delete(x, cp, t)
    new_size = if s == nil do size else size - 1 end
    %Rbtree{node: do_turn_black(s), size: new_size}
  end

  defp do_delete(_, _cp, nil), do: {nil, false}
  defp do_delete(x, cp, {c,h,y,yv,l,r}) do
    case cp.(x, y) do
      -1 ->
        {do_l, d} = do_delete(x, cp, l)
        t = {c,h,y,yv,do_l,r}
        if d do unbalanced_right(c, h-1, do_l, y, yv, r) else {t, false} end
       1 ->
        {do_r, d} = do_delete(x, cp, r)
        t = {c,h,y,yv,l,do_r}
        if d do unbalanced_left(c, h-1, l, y, yv, do_r) else {t, false} end
       0 ->
        if r == nil do
          if c == :black do blackify l else {l, false} end
        else
          {{do_r, d}, {m,v}} = do_delete_min r
          t = {c,h,m,v,l,do_r}
          if d do unbalanced_left(c, h-1, l, m, v, do_r) else {t, false} end
        end
    end
  end

# ----------------------------------------------------------------

# ----------------------------------------------------------------
# -- Set operations
# ----------------------------------------------------------------

  def join(nil, k, t2), do: insert(k, t2)
  def join(t1, k, nil), do: insert(k, t1)
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

  def merge(nil, t2), do: t2
  def merge(t1, nil), do: t1
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

  defp merge_eq(nil, nil), do: nil
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

  defp is_red({:red,_,_,_,_,_}), do: true
  defp is_red(_), do: false


# ----------------------------------------------------------------

  def split(_, nil), do: {nil, nil}
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

  def union(t1, nil), do: t1
  def union(nil, t2), do: turn_black(t2)
  def union(t1, {_,_,k,_,l,r}) do
    {do_l, do_r} = split(k, t1)
    join((union do_l, l), k, (union do_r, r))
  end

# ----------------------------------------------------------------

  def intersection(nil, _), do: nil
  def intersection(_, nil), do: nil
  def intersection(t1, {_,_,k,_,l,r}) do
    {do_l, do_r} = split(k, t1)
    if (member?(k, t1)) do
      join((intersection do_l, l), k, (intersection do_r, r))
    else
      merge((intersection do_l, l), (intersection do_r, r))
    end
  end

# ----------------------------------------------------------------

  def difference(nil, _), do: nil
  def difference(t1, nil), do: t1
  def difference(t1, {_,_,k,_,l,r}) do
    {do_l, do_r} = split k, t1
    merge((difference(do_l, l)), (difference(do_r, r)))
  end

# ----------------------------------------------------------------


  def reduce_nodes(%Rbtree{}=tree, acc, fun) do
    reduce_nodes(:in_order, tree, acc, fun)
  end

  def reduce_nodes(_order, %Rbtree{node: nil}, acc, _fun) do
    acc
  end

  def reduce_nodes(order, %Rbtree{node: root}, acc, fun) do
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
  def compare_items(term1, term2) do
    cond do
      term1 === term2 -> 0
      term1 < term2 -> -1
      term1 > term2 -> 1
      term1 == term2 ->
        case compare_items(hash_term(term1), hash_term(term2)) do
          0 -> compare_items(fallback_term_hash(term1),
            fallback_term_hash(term2))
          hash_comparison_result -> hash_comparison_result
        end
    end
  end

  defp hash_term(term) do
    :erlang.phash2(term, @key_hash_bucket)
  end

  defp fallback_term_hash(term) do
    :erlang.phash(term, @key_hash_bucket)
  end

end


defimpl Enumerable, for: Rbtree do
  def count(%Rbtree{size: size}), do: size
  def member?(%Rbtree{}=tree, key), do: Rbtree.has_key?(tree, key)
  def reduce(tree, acc, fun), do: Rbtree.reduce(tree, acc, fun)
end

defimpl Collectable, for: Rbtree do
  def into(original) do
    {original, fn
      tree, {:cont, {key, value}} -> Rbtree.insert(tree, key, value)
      tree, :done -> tree
      _, :halt -> :ok
    end}
  end
end

defimpl Inspect, for: Rbtree do
  import Inspect.Algebra

  def inspect(tree, opts) do
    concat ["#Rbtree<", Inspect.List.inspect(Rbtree.to_list(tree), opts), ">"]
  end
end