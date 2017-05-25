defmodule Rbtree do
  @moduledoc """
    Author: Ricky Han<rickylqhan@gmail.com>
    Based on Haskell Data.Set.RBtree implementation
    https://hackage.haskell.org/package/llrbtree-0.1.1/docs/src/Data-Set-RBTree.html

    {color, depth, key, value, left, right}
  """

# {c,d,k,v,l,r}

  @key_hash_bucket 4294967296

  defstruct(
    size: 0,
    node: nil,
    comparator: &__MODULE__.compare_items/2
  )

  # Attributes
  def null?(%Rbtree{node: node}) do
    case node do
      nil -> true
      _ -> false
    end
  end

  def height(%Rbtree{node: nil}), do: 0
  def height(%Rbtree{node: {_,h,_,_,_,_}}), do: h

  # Create
  def new(), do: empty()
  def new(k, v), do: from_list([{k, v}])
  def new(list) when is_list(list), do: from_list(list)


  def empty do
    %Rbtree{node: nil}
  end

  def singleton(key), do:
    singleton(key, nil)

  def singleton(key, value), do:
    %Rbtree{node: {:black, 1, key, value, nil, nil}}

  def size(%Rbtree{size: size}), do: size

  def from_list(list) when is_list(list) do
    Enum.reduce(list, empty(), fn(i, set) ->
      case i do
        {k, v} ->
          insert(set, k, v)
         k ->
          insert(set, k)
      end
    end)
  end

  def to_map(tree) do
    tree |> to_list |> Enum.into(%{})
  end

  def to_list(tree, acc \\ [])
  def to_list(%Rbtree{node: nil}, acc), do: acc
  def to_list(%Rbtree{node: node}, acc), do: do_to_list(node, acc)

  defp do_to_list(nil, acc), do: acc

  defp do_to_list({_,_,k,v,l,r}, acc) do
    case v do
      nil ->
        do_to_list(l, do_to_list(r, acc) ++ [k])
      _ ->
        do_to_list(l, do_to_list(r, acc) ++ [{k,v}])
    end

  end

  def member?(%Rbtree{node: nil}, _key), do: false
  def member?(%Rbtree{node: node, comparator: cp}, key) do
    do_member?(node, key, cp)
  end

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

  # def ordered?(tree, comparator \\ &<=/2)
  # def ordered?(tree, cp), do: tree |> to_list |> do_ordered(cp)
  # def do_ordered(l, cp \\ &<=/2, b \\ true)
  # def do_ordered([], _cp, _b), do: true
  # def do_ordered([_], _cp, _b), do: true
  # def do_ordered(_, _cp, false), do: false
  # def do_ordered([x | [y |_xys]=xs], cp, true), do: do_ordered(xs, cp, cp.(x,y) < 1)

  # Alt version
  def ordered?(tree), do: tree |> to_list |> ordered?(&compare_items/2)
  def ordered?([], _fun), do: true
  def ordered?(enum, fun) do
    match?({_}, Enum.reduce_while(enum, :start, &do_ordered?(&1, &2, fun)))
  end

  def do_ordered?(a, :start, _fun), do: {:cont, {a}}
  def do_ordered?(a, {b}, fun), do: fun.(a, b) && {:cont, {a}} || {:halt, nil}

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

  def minimum({_,_,k,v,nil,_}), do: {k,v}
  def minimum({_,_,_,_,l,_}), do: minimum(l)

  def maximum({_,_,k,_,_,nil}), do: k
  def maximum({_,_,_,_,_,r}), do: maximum(r)

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
  defp is_red({:red,_,_,_,_,_}), do: true
  defp is_red(_), do: false
#--------------------------------------------------------------

  def valid tree do
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
  defp do_insert({:black,h,k,v,l,r}=t, kx, vx, cp) do
    case cp.(kx, k) do
       0 -> t
      -1 -> do_balance_left(h, do_insert(l, kx, vx, cp), k, r, v)
       1 -> do_balance_right(h, l, k, do_insert(r, kx, vx, cp), v)
    end
  end
  defp do_insert({:red,h,k,v,l,r}=t, kx, vx, cp) do
    case cp.(kx, k) do
       0 -> t
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
  #   = "TypeNode" _ c:Color _ d:Atom _ l:TypeNode _ v:Atom _ r:TypeNode {
  #     return `%TypeNode{${c}, depth: ${d}, left: ${l}, key: ${v}, right: ${r}}`
  #   }
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

  defp balance_left(:black, h, {:red,_,y,yv,{:red,_,x,xv,a,b},c}, z, d), do:
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,h,z,nil,c,d,}}

  defp balance_left(:black, h, {:red,_,x,xv,a,{:red,_,y,yv,b,c}}, z, d), do:
    {:red,h+1,y,yv,{:black,h,x,xv,a,b},{:black,z,nil,c,d}}

  defp balance_left(k, h, l, x, r), do:
    {k,h,x,nil,l,r}

  defp balance_right(:black, h, a, x, {:red,_,y,yv,b,{:red,_,z,zv,c,d}}), do:
    {:red,h+1,y,yv,{:black,h,x,nil,a,b},{:black,h,z,zv,c,d}}
  defp balance_right(:black, h, a, x, {:red,_,z,zv,{:red,_,y,yv,b,c},d}), do:
    {:red,h+1,y,yv,{:black,h,x,nil,a,b},{:black,h,z,zv,c,d}}
  defp balance_right(k, h, l, x, r), do:
    {k,h,x,nil,l,r}

# ----------------------------------------------------------------

  defp unbalanced_left(c, h, {:black,_,_,_,_,_}=l, x, r), do:
    {balance_left(:black, h, (turn_red l), x, r), (c == :black)}
  defp unbalanced_left(:black, h, {:red,lh,lx,lxv,ll,{:black,_,_,_,_,_}=lr}, x, r), do:
    {{:black,lh,lx,lxv,ll,balance_left(:black, h, turn_red(lr), x, r)}, false}
  defp unbalanced_right(c, h ,l ,x ,{:black,_,_,_,_,_}=r), do:
    {balance_right(:black, h, l, x, turn_red(r)), c == :black}
  defp unbalanced_right(:black, h, l, x, {:red,rh,rx,rxv,{:black,_,_,_,_,_,_}=rl,rr}), do:
    {{:black,rh,rx,rxv,balance_right(:black, h, l, x, turn_red(rl)),rr}, false}

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
    tD = unbalanced_right(c, (h-1), do_l, x, r)
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
    tD  = unbalanced_left(c, (h-1), l, x, do_r)

    do_tD = {{c,h,x,v,l,do_r}, false}
    if d do
      {tD, m}
    else
      {do_tD, m}
    end
  end

# ----------------------------------------------------------------

  defp blackify({:red,_,_,_,_,_}=s), do: {turn_black(s), false}
  defp blackify(s), do: {s, true}

# ----------------------------------------------------------------

  def delete(%Rbtree{node: t, comparator: cp, size: size}, x) do
    new_size = if do_member?(t, x, cp) do size else size - 1 end
    {s, _} = do_delete(x, cp, t)
    %Rbtree{node: do_turn_black(s), size: new_size}
  end

  defp do_delete(_, _cp, nil), do: {nil, false}
  defp do_delete(x, cp, {c,h,y,yv,l,r}) do
    case cp.(x, y) do
      -1 ->
        {do_l, d} = do_delete(x, cp, l)
        t = {c,h,y,yv,do_l,r}
        if d do unbalanced_right(c, h-1, do_l, y, r) else {t, false} end
       1 ->
        {do_r, d} = do_delete(x, cp, r)
        t = {c,h,y,yv,l,do_r}
        if d do unbalanced_left(c, h-1, l, y, do_r) else {t, false} end
       0 ->
        if r == nil do
          if c == :black do blackify l else {l, false} end
        else
          {{do_r, d}, {m,v}} = do_delete_min r
          t = {c,h,m,v,l,do_r}
          if d do unbalanced_left(c, h-1, l, m, do_r) else {t, false} end
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

  defp join_lt(t1, k, {c,h,x,_,l,r}=t2, h1) do
    if h == h1 do
      {:red,h+1,k,nil,t1,t2} # value is nil for now
    else
      balance_left(c, h, (join_lt(t1, k, l, h1)), x, r)
    end
  end

  defp join_gt({c,h,x,_,l,r}=t1, k, t2, h2) do
    if h == h2 do
      {:red,h+1,k,nil,t1,t2} # value is nil for now
    else
      balance_right(c, h, l, x, (join_gt(r, k, t2, h2)))
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

  defp merge_lt(t1,{c,h,x,_,l,r}=t2, h1) do
    if h == h1 do
      merge_eq t1, t2
    else
      balance_left(c, h, (merge_lt(t1, l, h1)), x, r)
    end
  end

  defp merge_gt({c,h,x,_,l,r}=t1,
   t2, h2) do
    if h == h2 do
      merge_eq t1, t2
    else
      balance_right(c, h, l, x, (merge_gt(r, t2, h2)))
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


defimpl Inspect, for: Rbtree do
  import Inspect.Algebra

  def inspect(tree, opts) do
    concat ["#Rbtree<", Inspect.List.inspect(Rbtree.to_list(tree), opts), ">"]
  end
end


