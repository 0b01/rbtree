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

  def singleton key, val do
    %Rbtree{node: %Node{
        color: :black,
        depth: 1,
        key: key,
        value: val,
        size: 1,
        left: Leaf,
        right: Leaf
      }
    }
  end


  # def from_list list do
  #   Enum.reduce(list, __MODULE__.empty, fn i, acc -> insert(acc, i) end)
  # end

  def to_map(tree) do
    tree |> to_list |> Enum.into(%{})
  end

  def to_list(tree, acc \\ [])
  def to_list(%Rbtree{node: Leaf}, acc), do: acc
  def to_list(%Rbtree{node: node}, acc) do
    do_to_list(node, acc)
  end

  defp do_to_list(Leaf, acc), do: acc
  defp do_to_list(%Node{left: l, value: v, key: k, right: r}, acc) do
    do_to_list(l, do_to_list(r, acc) ++ [{k, v}])
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

  ##################################
  # Internals

  defp is_balanced? n do
    (is_black_same n) && (is_red_separate n)
  end

  defp is_black_same n do
    [h|t] = blacks n
    Enum.all?(t, &(&1==h))
  end

  defp blacks(n, acc \\ 0)
  defp blacks(Leaf, acc), do: [acc+1]
  defp blacks(%Node{color: :black, left: l, right: r}, acc), do:
    blacks(l, acc + 1) ++ blacks(r, acc + 1)
  defp blacks(%Node{color: :red,   left: l, right: r}, acc), do:
    blacks(l, acc    ) ++ blacks(r, acc    )

  defp is_red_separate(t), do: reds(:black, t)

  defp reds(_color, Leaf), do: true
  defp reds(:red, %Node{color: :red}), do: false
  defp reds(_color, %Node{color: c, left: l, right: r}), do:
    (reds c, l) && (reds c, r)

  def is_ordered(tree, comparator \\ &<=/2)
  def is_ordered(tree, cp), do: tree |> to_list |> do_is_ordered(cp)
  defp do_is_ordered(l, cp, b \\ true)
  defp do_is_ordered([], _cp, _b), do: true
  defp do_is_ordered([_], _cp, _b), do: true
  defp do_is_ordered(_, _cp, false), do: false
  defp do_is_ordered([x|[y|_xys]=xs], cp, true), do: do_is_ordered(xs, cp, cp.(x,y) < 1)

  # # Alt version
  # def ordered?(enum), do: ordered?(enum, &>=/2)
  # def ordered?([], _fun), do: true
  # def ordered?(enum, fun) do
  #   match?({_}, Enum.reduce_while(enum, :start, &do_ordered?(&1, &2, fun)))
  # end

  # def do_ordered?(a, :start, _fun), do: {:cont, {a}}
  # def do_ordered?(a, {b}, fun), do: fun.(a, b) && {:cont, {a}} || {:halt, nil}

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
  defp turn_black_with_leaf(Leaf), do: Leaf
  defp turn_black_with_leaf(node), do: turn_black(node)

  #############

  def minimum(%Node{left: Leaf, key: k, value: v}), do: {k, v}
  def minimum(%Node{left: l}), do: minimum(l)

  def maximum(%Node{right: Leaf, key: k, value: v}), do: {k, v}
  def maximum(%Node{right: l}), do: maximum(l)

  #############
  # to_string

  def to_string(%Rbtree{node: tree}) , do: do_to_string "", tree
  def do_to_string(_, Leaf), do: "\n"
  def do_to_string(pref, %Node{color: c, depth: h, key: k, value: v, left: l, right: r}), do:
       Atom.to_string(c) <> " {" <> Kernel.inspect(k) <> ", " <> Kernel.inspect(v) <> "}(" <> Integer.to_string(h) <> ")\n"
    <> pref <> "+ " <> do_to_string(("  " <> pref), l)
    <> pref <> "+ " <> do_to_string(("  " <> pref), r)

  #############
  defp is_red(%Node{color: :red}), do: true
  defp is_red(_), do: false
  #############

  defp valid tree do
    is_balanced(tree) && black_height(tree) && is_ordered(tree)
  end

  #####################################################################
  ## Basic Operations
  #####################################################################
  ## Insertion
  #  Chris Okasaki

  def insert(%RBTree{node: node, comparator: cp}, k, v), do: %{RBTree{node: turn_black(do_insert(node, k, v, cp))}}
  defp do_insert(Leaf, key, val, cp), do:
    %Node{
      color: :black,
      depth: 1,
      key: key,
      value: val,
      size: 1,
      left: Leaf,
      right: Leaf
    }
  defp do_insert(%Node{color: :black, depth: h, left: l, right: r, key: k}=t, kx, val, cp), do:
    case cp.(kx, k) do
       0 -> t
      -1 -> do_balance_left(h, do_insert(l, kx, val, cp), kx, r)
       1 -> do_balance_right(h, l, k, do_insert(r, kx, val, cp))       
    end
  defp do_insert(%Node{color: :red, depth:h, left: l, right: r, key: k, value: v}=t, kx, val, cp), do:
    case cp.(kx, x) do
       0 -> t
      -1 -> %Node{color: :red, height: h, left: do_insert(l, kx, val, cp), right: r, key: k, value: v}
       1 -> %Node{color: :red, height: h, left: l, right: do_insert(r, kx, val, cp), key: k, value:v}
    end

  defp do_balance_left(h, %Node{color: :red, depth: _, left: %Node{color: :red, depth: _, left: a, value: x, right: b}, value: y, right: c}, z, d), do:
    %Node{color: :red, depth: h+1, left: %Node{color: :black, depth: h, left: a, value: x, right: b}, value: y, right: %Node{color: :black, depth: h, left: c, value: z, right: d}}
  defp do_balance_left(h, %Node{color: :red, depth: _, left: a, value: x, right: %Node{color: :red, depth: _, left: b, value: y, right: c}},z ,d), do:
    %Node{color: :red, depth: h+1, left: %Node{color: :black, depth: h, left: a, value: x, right: b}, value: y, right: %Node{color: :black, depth: h, left: c, value: z, right: d}}
  defp do_balance_left(h, l, x, r), do:
    %Node{color: :black, depth: h, left: l, value: x, right: r}

  defp do_balance_right(h, a, x, %Node{color: :red, depth: _, left: b, value: y, right: %Node{color: :red, depth: _, left: c, value: z, right: d}}}), do:
    %Node{color: :red, depth: h+1, left: %Node{color: :black, depth: h, left: a, value: x, right: b}, value: y, right: %Node{color: :black, depth: h, left: c, value: z, right: d}}
  defp do_balance_right(h, a, x, %Node{color: :red, depth: _, left: %Node{color: :red, depth: _, left: b, value: y, right: c}, value: z, right: d}), do:
    %Node{color: :red, depth: h+1, left: %Node{color: :black, depth: h, left: a, value: x, right: b}, value: y, right: %Node{color: :black, depth: h, left: c, value: z, right: d}}
  defp do_balance_right(h,l,x,r), do:
    %Node{color: :black, depth: h, left: l, value: x, right: r}

  # # PEG.js parser
  # Start
  #   = Node
  # Node
  #   = "Node" _ c:Color _ d:Atom _ l:Node _ v:Atom _ r:Node {
  #     return `%Node{${c}, depth: ${d}, left: ${l}, value: ${v}, right: ${r}}`
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

  ########################################

  defp balance_left(:black, h, %Node{color: :red, depth: _, left: %Node{color: :red, depth: _, left: a, value: x, right: b}, value: y, right: c}, y, c), do:
    %Node{color: :red, depth: h+1, left: %Node{color: :black, depth: h, left: a, value: x, right: b}, value: y, right: %Node{color: :black, depth: h, left: c, value: z, right: d}}
  defp balance_left(:black, h, %Node{color: :red, depth: _, left: a, value: x, right: %Node{color: :red, depth: _, left: b, value: y, right: c}}, z, d), do:
    %Node{color: :red, depth: h+1, left: %Node{color: :black, depth: h, left: a, value: x, right: b}, value: y, right: %Node{color: :black, depth: h, left: c, value: z, right: d}}
  defp balance_left(k, h, l, x, r), do:
    %Node{color: k, depth: h, left: l, value: x, right: r}

  defp balance_right(:black, h, a, x, %Node{color: :red, depth: _, left: b, value: y, right: %Node{color: :red, depth: _, left: c, value: z, right: d}}), do:
    %Node{color: :red, depth: h+1, left: %Node{color: :black, depth: h, left: a, value: x, right: b}, value: y, right: %Node{color: :black, depth: h, left: c, value: z, right: d}}
  defp balance_right(:black, h, a, x, %Node{color: :red, depth: _, left: %Node{color: :red, depth: _, left: b, value: y, right: c}, value: z, right: d}), do:
    %Node{color: :red, depth: h,+,1, left: %Node{color: :black, depth: h, left: a, value: x, right: b}, value: y, right: %Node{color: :black, depth: h, left: c, value: z, right: d}}
  defp balance_right(k, h, l, x, r), do:
    %Node{color: k, depth: h, left: l, value: x, right: r}

  # TODO: unbalancedL

  ###################
  # Comparator
  def compare_items(term1, term2) do
    cond do
      term1 === term2 -> 0
      term1 < term2 -> -1
      term1 > term2 -> 1
      term1 == term2 ->
        case compare_items(hash_term(term1), hash_term(term2)) do
          0 -> compare_items(fallback_term_hash(term1), fallback_term_hash(term2))
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
