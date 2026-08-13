-- kerna-exact-matrix formal specification (Idris2)
-- Dependent types for pure integer matrices and key algebraic properties.
--
-- This module is a specification / proof sketch. The production runtime is Zig.
-- Correspondence between the two is maintained by careful design and future
-- extraction / validation work.
--
-- Author: Jacarri Sanders / Even The Odds Foundry LLC

module Matrix

%default total

||| Element type (mirrors Zig i64 for the core library)
public export
Element : Type
Element = Integer

||| Scale factor (mirrors Zig i32)
public export
Scale : Type
Scale = Integer

||| A matrix is indexed by its dimensions. We keep the scale as a parameter
||| for clarity; in a full development it can be made part of the type.
public export
data Matrix : (rows, cols : Nat) -> Type where
  MkMatrix : (scale : Scale) ->
             (data : Vect rows (Vect cols Element)) ->
             Matrix rows cols

||| Zero matrix
public export
zero : (rows, cols : Nat) -> Scale -> Matrix rows cols
zero rows cols s = MkMatrix s (replicate rows (replicate cols 0))

||| Identity matrix (square)
public export
identity : (n : Nat) -> Scale -> Matrix n n
identity n s = MkMatrix s (map (\i => map (\j => if i == j then 1 else 0) (range n)) (range n))
  where
    range : (k : Nat) -> Vect k Nat
    range Z = []
    range (S k) = 0 :: map S (range k)

||| Element-wise addition (requires equal dimensions — enforced by types)
public export
add : Matrix r c -> Matrix r c -> Maybe (Matrix r c)
add (MkMatrix s1 d1) (MkMatrix s2 d2) =
  if s1 == s2
     then Just (MkMatrix s1 (zipWith (zipWith (+)) d1 d2))
     else Nothing

||| Matrix multiplication (inner dimensions match by construction when called correctly)
public export
mul : {r, n, c : Nat} -> Matrix r n -> Matrix n c -> Matrix r c
mul (MkMatrix s1 d1) (MkMatrix s2 d2) =
  MkMatrix (s1 + s2) (map (\row => map (\col => sum (zipWith (*) row col)) (transpose d2)) d1)
  where
    -- Simplified; full Idris2 would use proven transpose and sum

||| Determinism statement (informal for now; can be turned into a proper theorem)
||| Same inputs always produce the same output because all operations are pure
||| functions on Integers with no ambient state.

||| Key algebraic properties we aim to prove fully:
|||
||| 1. add is associative and commutative when scales match
||| 2. mul is associative
||| 3. mul distributes over add
||| 4. identity is a left and right unit for mul
||| 5. scale arithmetic is correct under mul
|||
||| These properties are true of the mathematical model and are the target
||| of the formal development. The Zig implementation is written to mirror
||| this model as closely as possible.

-- End of specification sketch.
-- Future work: complete proofs of the five properties above using Idris2's
-- totality checker and equational reasoning.
