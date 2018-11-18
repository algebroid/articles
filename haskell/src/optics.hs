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

data Adapter s t a b = Adapter { from :: s -> a
                               , to   :: b -> t }

shift :: Adapter ((a, b), c) ((a', b'), c') (a, (b, c)) (a', (b', c'))
shift = Adapter f t where
    f ((a, b), c) = (a, (b, c))
    t (a', (b', c')) = ((a', b'), c')

data Prism s t a b = Prism { match :: s -> Either a t
                           , build :: b -> t }

the :: Prism (Maybe a) (Maybe b) a b
the = Prism (maybe (Right Nothing) Left) Just
