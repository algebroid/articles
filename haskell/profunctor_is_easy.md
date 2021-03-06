# Profunctor Opticsについて

> source: [Don't Fear the Profunctor Optics](https://github.com/hablapps/DontFearTheProfunctorOptics)

Opticsとは、レコードのフィールド、共用体のヴァリアント、コンテナの要素といった、あるデータ構造の構成要素を読み書きするためのアクセサの総称である。ここではOpticsの具体例としてLens, Adapter, Prism, Affineを取り上げる。

## Lens

雑に言うと、Lensはあるデータ**全体の**値(**whole** value)になんらかの焦点(focus)を絞ってアクセスするためのデータ構造である。ここでの「アクセスする」ということはどういうことかというと、ある与えられたデータ全体の焦点に対してviewとupdateができるということである。以下ではデータ全体を`s`，焦点を`a`としてviewとupdateを定義する。

```haskell
data Lens s a = Lens { view   :: s -> a
                     , update :: (a, s) -> s }
```

2-タプルの第一要素にアクセスする`π1`は次のように定義できる。

```haskell
π1 :: Lens (a, b) a
π1 = Lens v u where
    v = fst
    u (a', (_, b)) = (a', b)
```

使い方は以下のようになる。

```haskell
λ> view π1 (1, 'a')
1
λ> update π1 (2, (1, 'a'))
(2,'a')
```

これは便利だが、もっと良くすることができる。フォーカスしたとき型を変更して良いことにしてやるのである。つまり先ほどの定義では`(1, 'a')`を`("hi", 'a')`にすることはできなかった。これは多態性がなく弱いので、Lensの型を変更してやる。

```haskell
data Lens s t a b = Lens { view :: s -> a
                         , update :: (b, s) -> t }
```

`π1`の定義は以下のようになる。

```haskell
pi1 :: Lens (a, c) (b, c) a b
pi1 = Lens v u where
    v = fst
    u (b, (_, c)) = (b, c)
```

驚くべきことに、型以外の実装は先ほどの定義から変化していない。

```haskell
λ> update π1 ("hi", (1, 'a'))
("hi",'a')
```

Lensは以下の法則を満たす。

```haskell
viewUpdate :: Eq s => Lens s s a a -> s -> Bool
viewUpdate (Lens v u) s = u ((v s), s) == s

updateView :: Eq a => Lens s s a a -> a -> s -> Bool
updateView (Lens v u) a s = v (u (a, s)) == a

updateUpdate :: Eq s => Lens s s a a -> a -> a -> s -> Bool
updateUpdate (Lens v u) a1 a2 s = u (a2, (u (a1, s))) == u (a2, s)
```

この法則について非形式的に述べると、`update`はある焦点を排他的に変更すること、また`view`はフォーカスした値をそのまま抽出できることを確認している。

さて、タプルを変更したり要素を取り出すだけなら、Lensのような仰々しいシロモノが本当に必要なのかと思われるかもしれない。Lensは入れ子になった不変データ構造と向き合うとき、真の価値を発揮する。**Opticsは合成則を満たす**。これはOpticsの特徴の際たるものである。

例として、タプルが2重入れ子になっている以下のデータを考える。

```haskell
λ> update (π1 |.| π1 |.| π1) ("hi", (((1, 'a'), 2.0), True))
((("hi",'a'),2.0),True)
```

ここで合成関数 `|.|` は以下のように定義されている。

```haskell
(|.|) :: Lens s t a b -> Lens a b c d -> Lens s t c d
(Lens v1 u1) |.| (Lens v2 u2) = Lens v u where
    v = v2 . v1
    u (d, s) = u1 (u2 (d, v1 s), s)
```

とはいえ、このopticsの合成はぎこちないものである。なぜかというと、別の種類のopticsを合成しようとしたときに、また別の合成関数を定義する必要があるからだ。ライブラリごとの具体的な型について定義を考えると冗長の極みとなる。ライブラリのユーザーは、その合成関数についても深い知識を持たなければ使うことができなくなるだろう。これはのちに述べるprofunctor opticsによって解決される。

## Adapter

次のopticの具体例はAdapterである。名前から示唆されるが、このopticはなんらかの値を適合させることができる。特に、Adapterはデータ全体の値を焦点の値に適合させることができ、逆に焦点の値をデータ全体の値に適合させることもできる。実際には、このopticはデータ全体の値と焦点の値が同じ情報を持っていることを明らかにしている。多態的なAdapterの表現は次のように書ける。

```haskell
data Adapter s t a b = Adapter { from :: s -> a
                               , to   :: b -> t }
```

Adapterは次の法則を満たす。

```haskell
fromTo :: Eq s => Adapter s s a a -> s -> Bool
fromTo (Adapter f t) s = (t . f) s == s

toFrom :: Eq a => Adapter s s a a -> a -> Bool
toFrom (Adapter f t) a = (f . t) a == a
```

基本的に、このopticは同型写像として振る舞うことを要求している。

Adapterの例としてここでは`shift`を実装してみる。これはタプルの結合性を変更しても、タプルの情報が失われないということを示している。

```haskell
shift :: Adapter ((a, b), c) ((a', b'), c') (a, (b, c)) (a', (b', c'))
shift = Adapter f t where
    f ((a, b), c) = (a, (b, c))
    t (a', (b', c')) = ((a', b'), c')
```

次のコード片は単純な`shift`の利用例である。

```haskell
λ> from shift ((1, "hi"), True)
(1,("hi",True))
λ> to shift (True, ("hi", 1))
((True,"hi"),1)
```

## Prism

`Prism`は、全体の値を与えられた焦点から再構成できるにも関わらず、焦点の値が利用できない可能性があるとき現れる。代数的データ構造に慣れ親しんでいる読者は、Lensが直積型でPrismが直話型であると言えば分かるだろう。Prismは以下のように表現される：

```haskell
data Prism s t a b = Prism { match :: s -> Either a t
                           , build :: b -> t }
```

Prismは`match`と`build`という2つの演算を持つ。`match`は全体の値から焦点の値（最終的な値は`t`）を抽出することを試みる。一方、`build`は与えられた焦点から全体の値をいつでも再構築できる。ここでもPrismが満たすべき法則が存在するので示す。

```haskell
matchBuild :: Eq s => Prism s s a a -> s -> Bool
matchBuild (Prism m b) s = either b id (m s) == s

buildMatch :: (Eq a, Eq s) => Prism s s a a -> a -> Bool
buildMatch (Prism m b) a = m (b a) == Left a
```

これは`match`と`build`の間に一貫性がなければならないことを表明している。ある焦点をviewすることができるなら、それをbuildすると元の構造を手に入れることができる。また任意の焦点から全体をbuildすることができるなら、データ全体は焦点を含んでいなければならない。

よくあるprismの例として`the`がある。これは`Maybe`型の裏に隠れている値に焦点を当てることができる。

```haskell
the :: Prism (Maybe a) (Maybe b) a b
the = Prism (maybe (Right Nothing) Left) Just
```

さて、ここで常に`Maybe`の値から焦点を得ることができるとは限らないことに気づかれたと思う。しかしながら焦点があれば単に`Just`を用いて`Maybe`全体を構築できる：

```haskell
λ> match the (Just 1)
Left 1
λ> match the Nothing
Right Nothing
λ> build the 1
Just 1
λ> build the "hi"
Just "hi"
```

## Affine

Affineはあまり知られていない、lensとprismの中間に属するopticsである。これは[`Affine`](http://oleg.fi/gists/posts/2017-03-20-affine-traversal.html)または[`Optional`](http://julien-truffaut.github.io/Monocle/optics/optional.html)として知られている。lensのように、このopticsは与えられた焦点の値から全体の値を構築でき、しかしprismと違い、文脈情報を必要とする。Haskellでは、このopticsは以下のように書き下される：

```haskell
data Affine s t a b = Affine { preview :: s -> Either a t
                             , set     :: (b, s) -> t }
```

Affineは2つのメソッド`preview`と`set`を備えている。お気付きかも知れないが、これらのopticsはprismの`match`とlensの`update`から借りている。これらのメソッドの背後にある直観は、(lensやprismに)対応するものの背後にあるものと同じである。affineの則を示す：

```haskell
previewSet :: Eq s => Affine s s a a -> s -> Bool
previewSet (Affine p st) s = either (\a -> st (a, s)) id (p s) == s

setPreview :: (Eq a, Eq s) => Affine s s a a -> a -> s -> Bool
setPreview (Affine p st) a s = p (st (a, s)) == either (Left . const a) Right (p s)

setSet :: Eq s => Affine s s a a -> a -> a -> s -> Bool
setSet (Affine p st) a1 a2 s = st (a2, (st (a1, s))) == st (a2, s)
```

この則の直観はprismの背後にあるものと非常によく似ているが、重要な違いが一つある。値をセットしたとき、`preview`は必ずしもその値を返す必要はないが、しかしセットされた時のために、値は間違いなくセットされたものになる。実際には`set`は焦点の値を含む場合のみに全体の構造を更新する。

以下にaffineの利用例を示す。これは`(Maybe a, c)`の`a`にアクセスする例である:

```haskell
maybeFirst :: Affine (Maybe a, c) (Maybe b, c) a b
maybeFirst = Affine p st where
  p (ma, c) = maybe (Right (Nothing, c)) Left ma
  st (b, (ma, c)) = (ma $> b, c)
```

このデータ構造の背後には常に`a`が隠れているわけではない。一方、単に`b`だけから全体値`(Maybe b, c)`を構築することもできない。実際に構築するには、`c`を必要とする。それに加えて、affine則は全体値の中に焦点値が存在しないとき値を更新することができない。 したがって、我々は完全な`(Maybe b, c)`を文脈情報として必要とする。次に、このopticsの実行の仕方を見る：

```haskell
λ> preview maybeFirst (Just 1, "hi")
Left 1
λ> preview maybeFirst (Nothing, "hi")
Right (Nothing,"hi")
λ> set maybeFirst ('a', (Just 1, "hi"))
(Just 'a',"hi")
λ> set maybeFirst ('a', (Nothing, "hi"))
(Nothing,"hi")
```

ここでは教育的な理由から`maybeFirst`をモノリシックなやり方で実装したが、この例はどうも`π1`と`the`が結合しているようだということに気づかれたかも知れない。その直観は実際に良いものであり、opticsの合成の詳細を語る別のパートで再考する。
