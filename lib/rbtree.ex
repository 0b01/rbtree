defmodule Rbtree.Node do
  defstruct(
    color: :black,
    depth: 1,
    key: nil,
    value: nil,
    size: nil,
    left: nil,
    right: nil
  )

  def new(key, depth \\ 1) do
    %__MODULE__{key: key, depth: depth}
  end

  def color(%__MODULE__{}=node, color) do
    %__MODULE__{ node | color: color}
  end
end

defmodule Rbtree.Leaf do
  defstruct([nil])
end

defmodule Rbtree do
  @moduledoc """
    Author: Ricky Han<rickylqhan@gmail.com>
    Based on Haskell Data.Set.RBtree implementation
    https://hackage.haskell.org/package/llrbtree-0.1.1/docs/src/Data-Set-RBTree.html
  """
  alias Rbtree.Node
  alias Rbtree.Leaf


  @key_hash_bucket 4294967296

  defstruct node: nil, comparator: &__MODULE__.compare_items/2

  # Attributes

  def null?(%Rbtree{node: node}) do
    case node do
      Leaf -> true
      _ -> false
    end
  end

  def height(%Rbtree{node: Leaf}), do: 0
  def height(%Rbtree{node: %Node{depth: h}}), do: h

  # Create

  def empty do
    %Rbtree{node: Leaf}
  end

  def singleton key do
    %Rbtree{node: %Node{
        color: :black,
        depth: 1,
        key: key,
        left: Leaf,
        right: Leaf
      }
    }
  end


  def from_list list do
    Enum.reduce(list, empty(), fn(i, set) ->
      case i do
        {k, v} ->
          insert(set, k, v)
         k ->
          insert(set, k)
      end
    end)
  end

  # def to_map(tree) do
  #   tree |> to_list |> Enum.into(%{})
  # end

  def to_list(tree, acc \\ [])
  def to_list(%Rbtree{node: Leaf}, acc), do: acc
  def to_list(%Rbtree{node: node}, acc) do
    do_to_list(node, acc)
  end

  defp do_to_list(Leaf, acc), do: acc
  defp do_to_list(%Node{left: l, key: k, right: r}, acc) do
    do_to_list(l, do_to_list(r, acc) ++ [k])
  end

  def member?(%Rbtree{node: Leaf}, _key), do: false
  def member?(%Rbtree{node: node, comparator: cp}, key) do
    do_member?(node, key, cp)
  end

  defp do_member?(Leaf, _search_key, _comparator), do: false
  defp do_member?(%Node{left: l, key: nd_key, right: r}, srch_key, cp) do
    case cp.(srch_key, nd_key) do
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
  defp blacks(Leaf, acc), do: [acc + 1]
  defp blacks(%Node{color: :black, left: l, right: r}, acc), do:
    blacks(l, acc + 1) ++ blacks(r, acc + 1)
  defp blacks(%Node{color: :red,   left: l, right: r}, acc), do:
    blacks(l, acc    ) ++ blacks(r, acc    )

  defp is_red_separate(t), do: reds(:black, t)

  defp reds(_color, Leaf), do: true
  defp reds(:red, %Node{color: :red}), do: false
  defp reds(_color, %Node{color: c, left: l, right: r}), do:
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

  defp black_height(Leaf), do: true
  defp black_height(%Node{color: :black, depth: h}=t), do: do_black_height(t, h)
  defp black_height(_), do: {:error, "black_height"}
  defp do_black_height(Leaf, h), do: h == 0
  defp do_black_height(%Node{color: :red, depth: nh, left: l, right: r}, h), do:
    (h == nh - 1) && do_black_height(l, h) && do_black_height(r, h)
  defp do_black_height(%Node{color: :black, depth: nh, left: l, right: r}, h), do:
    (h == nh) && do_black_height(l, h - 1) && do_black_height(r, h - 1)

  defp turn_red(node), do: Node.color(node, :red)
  defp turn_black(node), do: Node.color(node, :black)
  defp do_turn_black(Leaf), do: Leaf
  defp do_turn_black(node), do: turn_black(node)

#--------------------------------------------------------------

  def minimum(%Node{left: Leaf, key: k}), do: k
  def minimum(%Node{left: l}), do: minimum(l)

  def maximum(%Node{right: Leaf, key: k}), do: k
  def maximum(%Node{right: l}), do: maximum(l)

#--------------------------------------------------------------
  # to_string

  def to_string(%Rbtree{node: tree}) , do: do_to_string "", tree
  def do_to_string(_, Leaf), do: "\n"
  def do_to_string(pref, %Node{color: c, depth: h, key: k, value: v, left: l, right: r}), do:
       Atom.to_string(c) <> " { " <> Kernel.inspect(k) <> ", " <> Kernel.inspect(v) <> " }("
       <> Integer.to_string(h) <> ")\n"
    <> pref <> "+ " <> do_to_string(("  " <> pref), l)
    <> pref <> "+ " <> do_to_string(("  " <> pref), r)

#--------------------------------------------------------------
  defp is_red(%Node{color: :red}), do: true
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
  def insert(%Rbtree{node: node, comparator: cp}, k, v), do:
    %Rbtree{node: turn_black(do_insert(node, k, v, cp))}

  defp do_insert(Leaf, key, val, _cp), do:
    %Node{
      color: :red,
      depth: 1,
      key: key,
      value: val,
      left: Leaf,
      right: Leaf
    }
  defp do_insert(
      %Node{color: :black, depth: h, left: l, right: r, key: x, value: xv}=t, kx, vx, cp) do
    case cp.(kx, x) do
       0 -> t
      -1 -> do_balance_left(h, do_insert(l, kx, vx, cp), x, r, xv)
       1 -> do_balance_right(h, l, x, do_insert(r, kx, vx, cp), xv)
    end
  end
  defp do_insert(
      %Node{color: :red, depth: h, left: l, right: r, key: x, value: xv}=t, kx, vx, cp) do
    case cp.(kx, x) do
       0 -> t
      -1 -> %Node{color: :red, depth: h,
          left: do_insert(l, kx, vx, cp), right: r, key: x, value: xv}
       1 -> %Node{color: :red, depth: h,
          left: l, right: do_insert(r, kx, vx, cp), key: x, value: xv}
    end
  end

  defp do_balance_left(h, %Node{
        color: :red,
        left: %Node{
          color: :red,
          left: a,
          key: x,
          value: xv,
          right: b},
        key: y,
        value: yv,
        right: c},
        z, d, xv), do:
    %Node{
      color: :red,
      depth: h+1,
      left: %Node{
        color: :black,
        depth: h,
        left: a,
        key: x,
        value: xv,
        right: b},
      key: y,
      value: yv,
      right: %Node{
        color: :black,
        depth: h,
        left: c,
        key: z,
        value: xv,
        right: d}}

  defp do_balance_left(h, %Node{
    color: :red, 
    left: a, 
    key: x, 
    value: xv, 
    right: %Node{
      color: :red, 
      left: b, 
      key: y, 
      value: yv, 
      right: c}},z ,d, xv), do:
    %Node{
      color: :red, 
      depth: h+1,
      left: %Node{
        color: :black,
        depth: h,
        left: a,
        key: x,
        value: xv,
        right: b},
        key: y,
        value: yv,
        right: %Node{
          color: :black,
          depth: h,
          left: c,
          key: z,
          value: xv,
          right: d}}

  defp do_balance_left(h, l, x, r, xv), do:
    %Node{color: :black, depth: h, left: l, key: x, value: xv, right: r}

  defp do_balance_right(h, a, x,
    %Node{color: :red, left: b, key: y, value: yv, right:
    %Node{color: :red, left: c, key: z, value: zv, right: d}}, xv), do:
      %Node{color: :red,
      depth: h+1,
      left: %Node{color: :black,
        depth: h,
        left: a,
        key: x,
        value: xv,
        right: b},
        key: y, value: yv,
        right: %Node{
          color: :black,
          depth: h,
          left: c,
          key: z,
          value: zv,
          right: d}}

  defp do_balance_right(h, a, x, %Node{
    color: :red,
    left: %Node{
      color: :red,
      left: b,
      key: y,
      value: yv,
      right: c},
      key: z,
      value: zv,
      right: d},xv), do:
      %Node{
        color: :red,
        depth: h+1,
        left: %Node{
          color: :black,
           depth: h,
           left: a,
           key: x,
           value: xv,
           right: b},
           key: y,
           value: yv,
        right: %Node{
          color: :black,
           depth: h,
           left: c,
           key: z,
           value: zv,
           right: d}}
  defp do_balance_right(h, l, x, r, xv), do:
    %Node{color: :black, depth: h, left: l, key: x, value: xv, right: r}

  # # PEG.js parser
  # Start
  #   = Node
  # Node
  #   = "Node" _ c:Color _ d:Atom _ l:Node _ v:Atom _ r:Node {
  #     return `%Node{${c}, depth: ${d}, left: ${l}, key: ${v}, right: ${r}}`
  #   }
  #   / "("node:Node")" {return node;}
  #   / Atom
  # Color
  #   = color:[BR] {return color === "B" ? "color: :black" : "color: :red";}
  # Atom
  #   = atom:[0-9a-zA-Z+-_]+ {return atom;}
  #   / "("a:Atom")" {return a;}
  # _ "whitespace"
  #   = [ \t\n\r]*

#--------------------------------------------------------------

  defp balance_left(:black, h, %Node{color: :red, depth: _,
    left: %Node{color: :red, depth: _, left: a, key: x, value: xv, right: b},
    key: y, value: yv, right: c}, z, d), do:
    %Node{color: :red, depth: h+1,
    left: %Node{color: :black, depth: h, left: a, key: x, value: xv, right: b},
    key: y, value: yv, right: %Node{color: :black, depth: h, left: c, key: z, right: d}}
  defp balance_left(:black, h, %Node{color: :red, depth: _, left: a, key: x, value: xv,
    right: %Node{color: :red, depth: _, left: b, key: y, value: yv, right: c}}, z, d), do:
    %Node{color: :red, depth: h+1,
    left: %Node{color: :black, depth: h, left: a, key: x, value: xv, right: b}, key: y, value: yv,
    right: %Node{color: :black, depth: h, left: c, key: z, right: d}}
  defp balance_left(k, h, l, x, r), do:
    %Node{color: k, depth: h, left: l, key: x, right: r}

  defp balance_right(:black, h, a, x,
    %Node{color: :red, depth: _, left: b, key: y, value: yv,
      right: %Node{color: :red, depth: _, left: c, key: z, value: zv, right: d}}), do:
    %Node{color: :red, depth: h+1,
    left: %Node{color: :black, depth: h, left: a, key: x, right: b}, key: y, value: yv,
    right: %Node{color: :black, depth: h, left: c, key: z, value: zv, right: d}}
  defp balance_right(:black, h, a, x, %Node{color: :red, depth: _,
    left: %Node{color: :red, depth: _, left: b, key: y, value: yv, right: c}, key: z, value: zv,
    right: d}), do:
    %Node{color: :red, depth: h+1,
    left: %Node{color: :black, depth: h, left: a, key: x, right: b}, key: y, value: yv,
    right: %Node{color: :black, depth: h, left: c, key: z, value: zv, right: d}}
  defp balance_right(k, h, l, x, r), do:
    %Node{color: k, depth: h, left: l, key: x, right: r}

# ----------------------------------------------------------------

  defp unbalanced_left(c, h, %Node{color: :black}=l, x, r), do:
    {balance_left(:black, h, (turn_red l), x, r), (c == :black)}
  defp unbalanced_left(:black, h,
    %Node{color: :red, depth: lh, left: ll, key: lx, value: lxv,
    right: %Node{color: :black}=lr}, x, r), do:
    {%Node{color: :black, depth: lh, left: ll, key: lx, value: lxv,
    right: balance_left(:black, h, turn_red(lr), x, r)}, false}

  defp unbalanced_right(c, h ,l ,x ,%Node{color: :black}=r), do:
    {balance_right(:black, h, l, x, turn_red(r)), c == :black}
  defp unbalanced_right(:black, h, l, x, %Node{color: :red, depth: rh,
    left: %Node{color: :black}=rl, key: rx, value: rxv, right: rr}), do:
    {%Node{color: :black, depth: rh,
    left: balance_right(:black, h, l, x, turn_red(rl)),
    key: rx, value: rxv, right: rr}, false}

  def delete_min(%Rbtree{node: Leaf}), do: empty()
  def delete_min(%Rbtree{node: t}) do
    {{s, _}, _} = do_delete_min t
    do_turn_black s
  end

  defp do_delete_min(Leaf), do: throw("error")
  defp do_delete_min(%Node{color: :black, left: Leaf, key: x, right: Leaf}), do:
    {{Leaf, true}, x}
  defp do_delete_min(%Node{color: :black, left: Leaf, key: x,
    right: %Node{color: :red}=r}), do:
    {{turn_black(r), false}, x}
  defp do_delete_min(%Node{color: :red, left: Leaf, key: x, right: r}), do:
    {{r, false}, x}
  defp do_delete_min(%Node{color: c, depth: h, left: l, key: x, right: r}) do
    {{do_l, d}, m} = do_delete_min l
    tD = unbalanced_right(c, (h-1), do_l, x, r)
    do_tD = { %Node{color: c, depth: h, left: do_l, key: x, right: r}, false}
    if d do
      {tD, m}
    else
      {do_tD, m}
    end
  end

# ----------------------------------------------------------------

  def delete_max(%Rbtree{node: Leaf}), do: empty()
  def delete_max(%Rbtree{node: t}) do
    {{s, _},_} = do_delete_max t
    do_turn_black s
  end

  defp do_delete_max(Leaf), do: throw("do_delete_max")
  defp do_delete_max(%Node{color: :black, left: Leaf, key: x, value: xv, right: Leaf}), do:
    {{Leaf, true}, x}
  defp do_delete_max(%Node{color: :black,
    left: %Node{color: :red}=l, key: x, right: Leaf}), do:
    {{turn_black(l), false}, x}
  defp do_delete_max(%Node{color: :red, left: l, key: x, right: Leaf}), do:
    {{l, false}, x}
  defp do_delete_max(%Node{color: c, depth: h, left: l, key: x, right: r}) do
    {{do_r, d}, m} = do_delete_max r
    tD  = unbalanced_left(c, (h-1), l, x, do_r)
    do_tD = {%Node{color: c, depth: h, left: l, key: x, right: do_r}, false}
    if d do
      {tD, m}
    else
      {do_tD, m}
    end
  end

# ----------------------------------------------------------------

  defp blackify(%Node{color: :red}=s), do: {turn_black(s), false}
  defp blackify(s), do: {s, true}

# ----------------------------------------------------------------

  def delete(%Rbtree{node: t, comparator: cp}, x) do
    {s, _} = do_delete(x, cp, t)
    do_turn_black s
  end

  defp do_delete(_, _cp, Leaf), do: {Leaf, false}
  defp do_delete(x, cp, %Node{color: c, depth: h, left: l, key: y, value: yv, right: r}) do
    case cp.(x, y) do
      -1 ->
        {do_l, d} = do_delete(x, cp, l)
        t = %Node{color: c, depth: h, left: do_l, key: y, value: yv, right: r}
        if d do unbalanced_right(c, h-1, do_l, y, r) else {t, false} end
       1 ->
        {do_r, d} = do_delete(x, cp, r)
        t = %Node{color: c, depth: h, left: l, key: y, value: yv, right: do_r}
        if d do unbalanced_left(c, h-1, l, y, do_r) else {t, false} end
       0 ->
        if r == Leaf do
          if c == :black do blackify l else {l, false} end
        else
          {{do_r, d}, m} = do_delete_min r
          t = %Node{color: c, depth: h, left: l, key: m, right: do_r}
          if d do unbalanced_left(c, h-1, l, m, do_r) else {t, false} end
        end
    end
  end

# ----------------------------------------------------------------


# ----------------------------------------------------------------
# -- Set operations
# ----------------------------------------------------------------

  def join(Leaf, k, t2), do: insert(k, t2)
  def join(t1, k, Leaf), do: insert(k, t1)
  def join(t1, k, t2) do
    h1 = height t1
    h2 = height t2
    cond do
      h1 == h2 ->
        %Node{color: :black, depth: h1+1, left: t1, key: k, right: t2}
      h1 < h2 ->
        turn_black(join_lt(t1, k, t2, h1))
      h1 > h2 ->
        turn_black(join_gt(t1, k, t2, h2))
    end
  end

  defp join_lt(t1, k,
    %Node{color: c, depth: h, left: l, key: x, right: r}=t2, h1) do
    if h == h1 do
      %Node{color: :red, depth: h+1, left: t1, key: k, right: t2}
    else
      balance_left(c, h, (join_lt(t1, k, l, h1)), x, r)
    end
  end

  defp join_gt(
    %Node{color: c, depth: h, left: l, key: x, right: r}=t1, k, t2, h2) do
    if h == h2 do
      %Node{color: :red, depth: h+1, left: t1, key: k, right: t2}
    else
      balance_right(c, h, l, x, (join_gt(r, k, t2, h2)))
    end
  end


# ----------------------------------------------------------------

  def merge(Leaf, t2), do: t2
  def merge(t1, Leaf), do: t1
  def merge(t1, t2) do
    h1 = height t1
    h2 = height t2
    cond do
      h1 < h2 -> turn_black(merge_lt(t1, t2, h1))
      h1 == h2 -> turn_black(merge_gt(t1, t2, h2))
      h1 > h2 -> turn_black(merge_eq(t1, t2))
    end
  end

  defp merge_lt(t1,
    %Node{color: c, depth: h, left: l, key: x, right: r}=t2, h1) do
    if h == h1 do
      merge_eq t1, t2
    else
      balance_left(c, h, (merge_lt(t1, l, h1)), x, r)
    end
  end

  defp merge_gt(%Node{color: c, depth: h, left: l, key: x, right: r}=t1,
   t2, h2) do
    if h == h2 do
      merge_eq t1, t2
    else
      balance_right(c, h, l, x, (merge_gt(r, t2, h2)))
    end
  end

  defp merge_eq(Leaf, Leaf), do: Leaf
  defp merge_eq(%{depth: h, left: l, key: x, right: r}=t1, t2) do
    m  = minimum t2
    do_t2 = delete_min t2
    do_h2 = height do_t2
    %Node{color: :red, left: rl, key: rx, value: rxv, right: rr} = r
    cond do
      h == do_h2 ->
        %Node{color: :red, depth: h+1,
        left: t1, key: m, right: do_t2}
      is_red l   ->
        %Node{color: :red, depth: h+1,
        left: (turn_black l), key: x,
        right: %Node{color: :black, depth: h, left: r, key: m, right: do_t2}}
      is_red r   ->
        %Node{color: :black, depth: h,
        left: %Node{color: :red, depth: h, left: l, key: x, right: rl}, key: rx, value: rxv,
        right: %Node{color: :red, depth: h, left: rr, key: m, right: do_t2}}
      true       ->
        %Node{color: :black, depth: h,
        left: (turn_red t1), key: m, right: do_t2}
    end
  end

# ----------------------------------------------------------------

  def split(_, Leaf), do: {Leaf, Leaf}
  def split(kx, %Node{left: l, key: k, right: r}) do
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

  def union(t1, Leaf), do: t1
  def union(Leaf, t2), do: turn_black(t2)
  def union(t1, %Node{left: l, key: k, right: r}) do
    {do_l, do_r} = split(k, t1)
    join((union do_l, l), k, (union do_r, r))
  end
# ----------------------------------------------------------------
  def intersection(Leaf, _), do: Leaf
  def intersection(_, Leaf), do: Leaf
  def intersection(t1, %Node{left: l, key: k, right: r}) do
    {do_l, do_r} = split(k, t1)
    if (member?(k, t1)) do
      join((intersection do_l, l), k, (intersection do_r, r))
    else
      merge((intersection do_l, l), (intersection do_r, r))
    end
  end
# ----------------------------------------------------------------
  def difference(Leaf, _), do: Leaf
  def difference(t1, Leaf), do: t1
  def difference(t1, %Node{left: l, key: k, right: r}) do
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


