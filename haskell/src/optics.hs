module Optics where

data Lens s t a b = Lens { view :: s -> a
                         , update :: (b, s) -> t }

pi1 :: Lens (a, c) (b, c) a b
pi1 = Lens v u where
    v = fst
    u (b, (_, c)) = (b, c)

(|.|) :: Lens s t a b -> Lens a b c d -> Lens s t c d
(Lens v1 u1) |.| (Lens v2 u2) = Lens v u where
    v = v2 . v1
    u (d, s) = u1 (u2 (d, v1 s), s)
