ここではPythonの小ネタを示す。Raymond Hettingerのツイート備忘録ともいう。 

## 数値

### `int`は`float`のサブセットではない

```python
>>> 1E8 == 10**8
True
>>> 1E100 == 10**100
False 
```

正確な比較を行いたい場合、`Decimal`を使う。

### 数値はアンダースコアで区切ることができる

`1_234_567`は合法な整数リテラルである。これは`1,234,567`のように数値を見やすくするための意味あいがある。

## 文字列

### f-stringsは好きなだけネストできる

```python
>>> f"{f'{len(dir(list))}'*5}"
'4646464646' 
```

### f-stringsは`\N{name}`を上手にパースできる

`\N{name}`は、文字列中において[ユニコード文字データベース](http://unicode.org/ucd/)に定義されている名称でユニコード文字を呼び出すことができるエスケープシーケンスである。

```python
>>> "\N{SUSHI}"
'🍣'
```

Python 3.6にて導入されたf-stringsは賢いので、`\N{name}`と混在しても文字列を間違いなくパースしてくれる。

```python
>>> ordinal, state = 50, "Hawaiʻi"
>>> print(f'{ordinal} \N{long rightwards arrow} {state}')
50 ⟶ Hawaiʻi
```

### `str.find()`より`str.index()`を使うべき

`str.find()`は値が見つからなかった場合`-1`を返すが、Pythonにとってこの値は負インデックスと解釈できてしまう（`"abc"[-1] == 'c'`）。これは空文字列以外の正しいインデックスを指す値である。`str.index()`は値が見つからない場合エラーを返す。間違いを起こさないためにはなるべく`str.index()`を使った方がよい。

### 最小労力の原理

これは文字列に限った問題ではないが、ある特定の問題を解決する際はその目的に特化した方法を採るべきで、一般的な方法を使わないほうがよい。

具体例：

* 行末を削除するためには`rstrip()`を使うべきで`strip()`は使わない
* `str.replace()`が使える場面で`re.sub()`を使うべきでない
* Fabricで済む場面でAnsibleを使わない（これは文字列と関係ない）

## リスト

### スライスの間違いにご用心

```python
>>> s = 'abc'
>>> s[-3:] # last three
'abc'
>>> s[-2:] # last two
'bc'
>>> s[-1:] # last one
'c'
>>> s[-0:] # oops!
'abc'
```

そんなバカなと思うかもしれないが以外にもハマるという声がある。

## ループ中でリストの要素を変更せず、データを生成するほうがよい

```python
# Just okay
for i, x in enumerate(data):
    data[i] *= factor

# Better
scaled_data = [x * factor for x in data]
```

ループ中で副作用のあるコードはデータの変更を追跡しづらいため、下のようにしたほうがよい。

## ディクショナリ

### ディクショナリの要素を文字列中に楽に展開する

適当なディクショナリがあるとき、`str.format_map()`を使うと簡単に要素を文字列整形できる。

```python
"""your name: {name}
your status: {status}
your affiliation: {company}""".format_map(info)
```

やや劣る方法:

```python
f"""your name: {info['name']}
your status: {info['status']}
your affiliation: {info['company']}"""
```

## set

### Pythonのsetは半順序である

理由は`a <= b`は`a.issubset(b)`であるためである。

## 型アノテーション

### サードパーティライブラリの間違った型アノテーションをユーザー側で修正する

具体例：`algebra`モジュールの`quadratic`という関数が誤って`Tuple[float, float]`とマークされている。

```python
algebra.quadratic.__annotations__['return'] = typing.Tuple[complex, complex]
```

## クラス

### Python 3では`__eq__()`メソッドを拡張またはオーバーライドした場合、そのクラスはunhashableになる

hashによる同値性テストが事故を起こすのを防いでいる。詳しくは[Python における hashable](https://qiita.com/yoichi22/items/ebf6ab3c6de26ddcc09a)を参照。

## エラー処理

### `raise from None`イディオム

ある例外を新しい例外で置き換えるとき、この方法で例外の連鎖を止めることができる。


```python
try:
    f(x)
except MisleadingError:
   raise CorrectError from None
```

## ユーティリティ

### 標準出力をキャプチャする

以下のコードは`pow`関数のhelp内容を`help.txt`にリダイレクトしている。

```python
with open('help.txt', 'w') as f:
    with contextlib.redirect_stdout(f):
        help(pow)
```
