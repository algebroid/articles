> この記事はwtfPythonの翻訳ですが、最新の内容に追従していません。
>
> [satwikkansal/wtfPython: A collection of subtle and tricky Python examples](https://github.com/satwikkansal/wtfPython)

## 前文要約

* Pythonはいい言語。
* でも初心者には一見わかりにくい挙動をすることもある。
* ここでは古典的でトリッキーな例を集めた。
* トリッキーといっても大したことのない例もわりとある。
* 経験を積んだPythonプログラマならだいたい知っているはず。

## 使い方

だいたい上から順に読むとよい。

* 答えを見る前に（出力も見ずに）予測しながらコードを読んだほうがよい。
  * 経験豊かなPythonistaなら何が起きるか見抜けるはず。
* それから出力が予想と正しいか確かめよう。
* どうしてそのような出力になったか説明していただきたい。
  * わからない場合は解説を読み、それでもわからない場合は[issueを立てていただきたい](https://github.com/satwikkansal/wtfPython)。

## 代入を無視するインタプリタ？

```python
>>> value = 11
>>> valuе = 32
>>> value
11
```

### 解説

2行目のvaluеのеはキリル文字(unicode)である。つまり1行目と2行目は違う変数である。

## うさんくさいコード(Python 2.x系限定)

```python
def square(x):
    sum_so_far = 0
    for counter in range(x):
        sum_so_far = sum_so_far + x
	return sum_so_far

print(square(10))
# => 10
```

3系では動かないというのがヒント。

### 解説

タブ文字とスペースが混ざっている。具体的には`return`部のインデントがタブになっている。

Pythonではタブ文字は8つのスペースに置き換えられる。なので`return sum_so_far`はループ内部に入る。

Python 3.xは、タブ文字とスペースの混用に対してエラーを出す。

## ちょっとこのハッシュヤバくね？

```python
some_dict = {}
some_dict[5.5] = "Ruby"
some_dict[5.0] = "JavaScript"
some_dict[5] = "Python"
```

**出力**

```python
>>> some_dict[5.5]
"Ruby"
>>> some_dict[5.0]
"Python"
>>> some_dict[5]
"Python"
```

なぜ`"JavaScript"`が消えてしまうのか？((原文は"Python" destroyed the existence of "JavaScript"?という小洒落た煽りだが、無視で。))

### 解説

キー`5`(`int`)はハッシュ値を計算する際に`float`の`5.0`に変換されている。

これは等しい値(`5 == 5.0`)のハッシュは等しくなること(`hash(5) == hash(5.0)`)を要請することから来る問題である((9月2日現在説明が不十分という[Issue](https://github.com/satwikkansal/wtfpython/issues/10)が立っている))。Python固有の問題ではない。

詳しくは以下。

> [python - Why can a floating point dictionary key overwrite an integer key with the same value? - Stack Overflow](https://stackoverflow.com/questions/32209155/why-can-a-floating-point-dictionary-key-overwrite-an-integer-key-with-the-same-v/32211042#32211042)

## 評価タイミングの食い違い

```python
array = [1, 8, 15]
g = (x for x in array if array.count(x) > 0)
array = [2, 8, 22]
```

**出力**

```python
>>> print(list(g))
[8]
```

### 解説

ジェネレータ内包では、`in`節は宣言時に評価され、`if`節以降は実行時に評価される。

この例だと、ジェネレータ内部の`x`は`1, 8, 15`と評価される。しかしif節の`array`は`[2, 8, 22]`に再割り当てされているので、`8`だけが1つカウントされる。ゆえにジェネレータは8だけを返す。

## 辞書をイテレート中に変更する

```python
x = {0: None}

for i in x:
    del x[i]
    x[i+1] = None
    print(i)
```

**出力**

```
0
1
2
3
4
5
6
7
```

8回ループして止まる((実装依存。Yes, it runs for exactly **eight** times and stopsと述べられているが、私の環境では5回のループで止まった))。

### 解説

* まず辞書をイテレーション中に編集してはいけない。
* 8回エントリを削除した時点で、より多くのキーを保持するために辞書をリサイズしている。実装詳細の話であり言語仕様ではない。
* 類似例について[Stack Overflowのスレ](https://stackoverflow.com/questions/44763802/bug-in-python-dict)で解説されている。

(興味ぶかいが、なんだかよくわからない…)

## リストの要素をイテレート中に削除する

```python
list_1 = [1, 2, 3, 4]
list_2 = [1, 2, 3, 4]
list_3 = [1, 2, 3, 4]
list_4 = [1, 2, 3, 4]

for idx, item in enumerate(list_1):
    del item

for idx, item in enumerate(list_2):
    list_2.remove(item)

for idx, item in enumerate(list_3[:]):
    list_3.remove(item)

for idx, item in enumerate(list_4):
    list_4.pop(idx)
```

**出力**

```python
>>> list_1
[1, 2, 3, 4]
>>> list_2
[2, 4]
>>> list_3
[]
>>> list_4
[2, 4]
```

特に`list_2`, `list_4`の挙動を推察できるだろうか？

### 解説

大前提として、イテレート中にリストを変更するのはよくない。こうしたことをしたい場合、スライス記法`some_list[:]`でリストをコピーすべきである。

#### `del`, `remove`, `pop`の挙動の違い

* `remove`は最初にマッチした値を削除する。特定のインデックスを指し示すものではないので、値が存在しないと`ValueError`を発生させる。
* `del`は特定のインデックスを削除する（これが`list_1`が影響を受けない理由である）。不正なインデックスが指定されたときは`IndexError`を発生させる。
* `pop`は特定のインデックスの値を削除しその値を返す。不正なインデックスが指定されたときは`IndexError`を発生させる。

#### `[2, 4]`という出力はなんなのか？

リストの反復はインデックスごとに行われる。`1`を`list_2`または`list_4`から削除したとき、リストの中身は`[2, 3, 4]`となっている。つまり残った要素はシフトダウンされ、`2`はインデックス0に、`3`はインデックス1より…といった具合になる。次のループではインデックスは1となり、これは`3`を削除する。`2`に対する操作は完全にスキップされる。以下同様に`4`への操作もスキップされる。

[Stack Overflowのこのスレ](https://stackoverflow.com/questions/45877614/how-to-change-all-the-dictionary-keys-in-a-for-loop-with-d-items)に辞書に関する同様の例が説明されている。

## 文字列

```python
>>> print("\\ some string \\")
>>> print(r"\ some string")
>>> print(r"\ some string \")
```

**出力(3行目)**

```
    File "<stdin>", line 1
      print(r"\ some string \")
                             ^
SyntaxError: EOL while scanning string literal
```

### 解説

* まずrを接頭辞とするraw文字列リテラルでは、バックスラッシュは特殊な意味を持たない。どうしてこうなるのか？
* インタプリタが実際にやっていることは、単純にバックスラッシュの挙動を変更している。（"so they pass themselves and the following character through."）ここ何をいってるのかよくわからなかった。[ここ](https://stackoverflow.com/questions/647769/why-cant-pythons-raw-string-literals-end-with-a-single-backslash)を参考にすると、raw文字列は有効な文字列リテラルである必要があるから、バックスラッシュで終われないということだと思う。

## でっかい文字列を作ろう！

これはなんじゃこりゃ！という感じのコードではないのだが、気をつけておくといいことなので紹介するよ(o^^o)

```python
def add_string_with_plus(iters):
    s = ""
    for i in range(iters):
        s += "xyz"
    assert len(s) == 3*iters

def add_string_with_format(iters):
    fs = "{}"*iters
    s = fs.format(*(["xyz"]*iters))
    assert len(s) == 3*iters

def add_string_with_join(iters):
    l = []
    for i in range(iters):
        l.append("xyz")
    s = "".join(l)
    assert len(s) == 3*iters

def convert_list_to_string(l, iters):
    s = "".join(l)
    assert len(s) == 3*iters
```

**出力**

```python
>>> timeit(add_string_with_plus(10000))
100 loops, best of 3: 9.73 ms per loop
>>> timeit(add_string_with_format(10000))
100 loops, best of 3: 5.47 ms per loop
>>> timeit(add_string_with_join(10000))
100 loops, best of 3: 10.1 ms per loop
>>> l = ["xyz"]*10000
>>> timeit(convert_list_to_string(l, 10000))
10000 loops, best of 3: 75.3 µs per loop
```

### 解説

* [timeitについてはここを参照](https://docs.python.org/3/library/timeit.html)。コードスニペットの実行時間を測るのに使われる。
* Pythonでは`+`を長い文字列を生成するのに使ってはいけない。`str`は不変であり、`+`の右左の文字列は常にコピーされる。長さ10の文字列を結合する操作を繰り返すとき、`(10+10) + ((10+10)+10) + (((10+10)+10) + (10+10)+10) = 90`文字のコピーが生じる。これはパフォーマンス上、文字列長さnに対し`O(n^2)`の悪影響を与える。
* よって、文字列の結合には`.format`または`%`を使うべきである((f-stringも))（ただし短い文字列に対しては少しだけ`+`より遅くなる）。
* すでに反復可能な状態としてデータを持っている場合は、`''.join(iterable_object)`が非常に高速である。

## 文字列連結のインタプリタによる最適化

```python
>>> a = "some_string"
>>> id(a)
140420665652016
>>> id("some" + "_" + "string") # Notice that both the ids are same.
140420665652016
# using "+", three strings:
>>> timeit.timeit("s1 = s1 + s2 + s3", setup="s1 = ' ' * 100000; s2 = ' ' * 100000; s3 = ' ' * 100000", number=100)
0.25748300552368164
# using "+=", three strings:
>>> timeit.timeit("s1 += s2 + s3", setup="s1 = ' ' * 100000; s2 = ' ' * 100000; s3 = ' ' * 100000", number=100)
0.012188911437988281
```

### 解説

* `+=`は`+`より高速である。これは最初の文字列を破棄しないため（例では`s1`）。
* CPythonはいくつかのケースに対し、現存する不変オブジェクトを再利用しようとする。これが`a = "some_string"`と`"some" + "_" + "string"`の`id`が等しくなった理由である。詳しくは[ここ](https://stackoverflow.com/questions/24245324/about-the-changing-id-of-an-immutable-string)を参照。

## こんなところに`else`節？

forループに対する`else`節。

```python
def does_exists_num(l, to_find):
    for num in l:
        if num == to_find:
            print("Exists!")
            break
    else:
        print("Does not exist")
```

**出力**

```python
>>> some_list = [1, 2, 3, 4, 5]
>>> does_exists_num(some_list, 4)
Exists!
>>> does_exists_num(some_list, -1)
Does not exist
```

例外ハンドリングに対する`else`節。

```python
try:
    pass
except:
    print("Exception occurred!!!")
else:
    print("Try block executed successfully...")
```

**出力**

```
Try block executed successfully...
```

### 解説

* forループ中で`break`が起こらなかったとき`else`節が実行される。
* tryブロックの後にくる`else`節は完了節(completion clause)とも呼ばれる。その名の通り、tryブロックが成功裏に完了したとき実行される。

## `is`の不思議な挙動

(インターネットでは) かなり有名な挙動である。

```python
>>> a = 256
>>> b = 256
>>> a is b
True

>>> a = 257
>>> b = 257
>>> a is b
False

>>> a = 257; b = 257
>>> a is b
True
```

### 解説

#### `is`と`==`の違い

* `is`はオペランドが同じオブジェクトを参照しているかを調べる。
* `==`は値が同じかどうか調べている。
* 2つの違いが明確な例を挙げる。

```python
>>> [] == []
True
>>> [] is [] # These are two empty lists at two different memory locations.
False
```

#### `256`はすでに存在するオブジェクトであり、`257`はそうではない

実は、`-5`から`256`までの数値は、Pythonを起動した時点で割り当てされている。これらの数は非常によく使われるためである。

https://docs.python.org/ja/3/c-api/long.html から引用する。

> 現在の実装では、-5 から 256 までの全ての整数に対する整数オブジェクトの配列を保持するようにしており、この範囲の数を生成すると、実際には既存のオブジェクトに対する参照が返るようになっています。従って、1 の値を変えることすら可能です。変えてしまった場合の Python の挙動は未定義です :-)

```python
>>> id(256)
10922528
>>> a = 256
>>> b = 256
>>> id(a)
10922528
>>> id(b)
10922528
>>> id(257)
140084850247312
>>> x = 257
>>> y = 257
>>> id(x)
140084850247440
>>> id(y)
140084850247344
```

上のコードはインタプリタが`y = 257`を割り当てる際、あまり賢くないことを示している(x = 257が存在するのに、再利用せず新しいオブジェクトを生成している)。

#### しかし、同じ値を同じ行で初期化するときは`a`と`b`は同じオブジェクトになる

```python
>>> a, b = 257, 257
>>> id(a)
140640774013296
>>> id(b)
140640774013296
>>> a = 257
>>> b = 257
>>> id(a)
140640774013392
>>> id(b)
140640774013488
```

* 同じ行で同じ値(`257`)を割り当てると、Pythonはオブジェクトを再利用する。
* 行を分離すると`257`がすでに存在しているか分からない(REPL限定の話で対話環境は対話行ごとにコンパイルを行うから)。
* `.py`ファイル中で書いたプログラムはREPLと同じ挙動になるとは限らない。ファイルは一度にコンパイルされるため。

## `is not ...`は`is (not ...)`とは異なる

```python
>>> 'something' is not None
True
>>> 'something' is (not None)
False
```

### 解説

* `is not`で単一の二項演算子である。`is`と`not`を別々に使うのとは異なる動作をしていることに注意。
* `is not`は両側の変数が同じオブジェクトを参照しているときに`False`を返し、そうでないときは`True`となる。

## ループ中で定義した関数が、同じ出力しかしない

```python
funcs = []
results = []
for x in range(7):
    def some_func():
        return x
    funcs.append(some_func)
    results.append(some_func())

funcs_results = [func() for func in funcs]
```

```python
>>> results
[0, 1, 2, 3, 4, 5, 6]
>>> funcs_results
[6, 6, 6, 6, 6, 6, 6]
```

`some_func`を`funcs`に追加する時点では`x`の値がすべて異なるのだが、すべての関数は`6`を返す。

あるいは、

```python
>>> powers_of_x = [lambda x: x**i for i in range(10)]
>>> [f(2) for f in powers_of_x]
[512, 512, 512, 512, 512, 512, 512, 512, 512, 512]
```

### 解説

* ループ中で定義された関数は、その本体ではループ変数を用いる。ループ関数のクロージャは変数(`x`)に束縛され、値には束縛されない。よって、すべての関数は変数に割り当てられた最後の値(`6`)を利用する。
* 最初のような望ましい挙動を得るためには、ループ変数を名前付き変数(オプション引数)として関数に渡してやるとよい。ここで考えて欲しい、*なぜこれでうまくいくのか？*

```python
funcs = []
for x in range(7):
    def some_func(x=x):
        return x
    funcs.append(some_func)
```

**出力**

```python
>>> funcs_results = [func() for func in funcs]
>>> funcs_results
[0, 1, 2, 3, 4, 5, 6]
```

理由は、関数のスコープ内部で変数を定義し直しているからである。

## ループ変数がローカルスコープ外に漏れる！

**1.**

```python
for x in range(7):
    if x == 6:
        print(x, ': for x inside loop')
print(x, ': x in global')
```

**出力**

```python
6 : for x inside loop
6 : x in global
```

`x`をforループの外では一度も定義していないのに…

**2.**

```python
# This time let's initialize x first
x = -1
for x in range(7):
    if x == 6:
        print(x, ': for x inside loop')
print(x, ': x in global')
```

**出力**

```
6 : for x inside loop
6 : x in global
```

**3.**

```python
x = 1
print([x for x in range(5)])
print(x, ': x in global')
```

**出力(Python 2.x)**

```
[0, 1, 2, 3, 4]
4 : x in global
```

**出力(Python 3.x)**

```
[0, 1, 2, 3, 4]
1 : x in global
```

### 解説

* Pythonのforループは新たにスコープを作らない。定義済みのループ変数はそのまま残る。2番目の例が示しているように、これは既存の変数をも再束縛する。
* リスト内包はPython 2.xとPython 3.xとで扱いが異なる。[What’s New In Python 3.0](https://docs.python.org/ja/3/whatsnew/3.0.html)を引く。

> リスト内包表記はもう `[... for var in item1, item2, ...]` という構文形をサポートしません。代わりに `[... for var in (item1, item2, ...)]` を使用してください。また、リスト内包表記は異なるセマンティクスを持つことに注意してください。リスト内包表記は list() コンストラクタ内のジェネレータ式の糖衣構文に近く、特にループの制御変数はスコープ外ではもう使用することができません。

## ○×ゲーム、初手でいきなり勝利！

```python
# Let's initialize a row
row = [""]*3 #row i['', '', '']
# Let's make a board
board = [row]*3
```

**出力**

```python
>>> board
[['', '', ''], ['', '', ''], ['', '', '']]
>>> board[0]
['', '', '']
>>> board[0][0]
''
>>> board[0][0] = "X"
>>> board
[['X', '', ''], ['X', '', ''], ['X', '', '']]
```

3つも`'X'`を代入してないんだけど、どういうことなのさ？

(これも有名だと思う)

### 解説

`row`は`["", "", ""]`というデータを指し示している。

`[row] * 3`で`board`を初期化すると、`board[0]`, `board[1]`, `board[2]`は同じ`row`を参照する。

## デフォルト可変引数にご用心

```python
def some_func(default_arg=[]):
    default_arg.append("some_string")
    return default_arg
```

**出力**

```python
>>> some_func()
['some_string']
>>> some_func()
['some_string', 'some_string']
>>> some_func([])
['some_string']
>>> some_func()
['some_string', 'some_string', 'some_string']
```

### 解説

関数のデフォルト可変引数は関数呼び出しごとに初期化されず、最新の割り当てられた値をデフォルト引数として用いる。`some_func`に明示的に`[]`を渡すことにより、`default_arg`が使われることを避けることができる。

```python
def some_func(default_arg=[]):
    default_arg.append("some_string")
    return default_arg
```

**出力**

```python
>>> some_func.__defaults__ #This will show the default argument values for the function
([],)
>>> some_func()
>>> some_func.__defaults__
(['some_string'],)
>>> some_func()
>>> some_func.__defaults__
(['some_string', 'some_string'],)
>>> some_func([])
>>> some_func.__defaults__
(['some_string', 'some_string'],)
```

可変引数にまつわるバグを避ける一般的な方法として、まず`None`をデフォルト値として割り当て、あとでその引数に値が渡されているかチェックするというものがある。

```python
def some_func(default_arg=None):
    if not default_arg:
        default_arg = []
    default_arg.append("some_string")
    return default_arg
```

## 同じオペランド、異なる結果

**1**

```python
a = [1, 2, 3, 4]
b = a
a = a + [5, 6, 7, 8]
```

**出力**

```python
>>> a
[1, 2, 3, 4, 5, 6, 7, 8]
>>> b
[1, 2, 3, 4]
```

**2**

```python
a = [1, 2, 3, 4]
b = a
a += [5, 6, 7, 8]
```

**出力**

```python
>>> a
[1, 2, 3, 4, 5, 6, 7, 8]
>>> b
[1, 2, 3, 4, 5, 6, 7, 8]
```

### 解説

* `a += b`と`a = a + b`は同じ動作をしない。
* `a + [5,6,7,8]`は新しいオブジェクトを生成し、`a`に新しい参照をセットする。`b`の内容にはなんら変更がない。
* `a += [5,6,7,8]`は実際には`extend`関数であり、`a`と`b`は同じオブジェクトを指し示したまま、インプレースで変更が加えられる。

## 変更不能オブジェクトを変更する

```python
some_tuple = ("A", "tuple", "with", "values")
another_tuple = ([1, 2], [3, 4], [5, 6])
```

**出力**

```
>>> some_tuple[2] = "change this"
TypeError: 'tuple' object does not support item assignment
>>> another_tuple[2].append(1000) #This throws no error
>>> another_tuple
([1, 2], [3, 4], [5, 6, 1000])
>>> another_tuple[2] += [99, 999]
TypeError: 'tuple' object does not support item assignment
>>> another_tuple
([1, 2], [3, 4], [5, 6, 1000, 99, 999])
```

タプルって変更できないはずでしたよね…

### 解説

* https://docs.python.org/ja/3.6/reference/datamodel.html より引用。

> 変更不能なシーケンス型のオブジェクトは、一度生成されるとその値を変更することができません。 (オブジェクトに他のオブジェクトへの参照が入っている場合、参照されているオブジェクトは変更可能なオブジェクトでもよく、その値は変更される可能性があります; しかし、変更不能なオブジェクトが直接参照しているオブジェクトの集合自体は、変更することができません。)

* `+=`はインプレースにリストを変更する。要素の割り当ては動作しないが、例外が発生した時点で、要素はインプレースに変更されている。

## スコープ中に定義されていない変数を使う

```python
a = 1
def some_func():
    return a

def another_func():
    a += 1
    return a
```

**出力**

```python
>>> some_func()
1
>>> another_func()
UnboundLocalError: local variable 'a' referenced before assignment
```

### 解説

* スコープ中で変数を割り当てたときに、その変数はローカル変数として扱われる。つまり`a`は`another_func`内ではローカルになっているのだが、初期化されていないためにエラーを投げる。
* Pythonの名前空間とスコープ解決についてもっと知りたい人は[この記事を参照](http://sebastianraschka.com/Articles/2014_python_scope_and_namespaces.html)。
* `another_func`の外側のスコープの変数を変更したいときは、`global`を使おう。

```python
def another_func()
    global a
    a += 1
    return a
```

**出力**

```python
>>> another_func()
2
```

## 外側のスコープから消える変数

```python
e = 7
try:
    raise Exception()
except Exception as e:
    pass
```

**出力(Python 2.x)**

```python
>>> print(e)
# prints nothing
```

**出力(Python 3.x)**

```python
>>> print(e)
NameError: name 'e' is not defined
```

### 解説

ソース: https://docs.python.org/3/reference/compound_stmts.html#except

例外が`as`により割り当てられると、その変数はexcept節の終わりに除去される。

以下のコードが

```python
except E as N:
    foo
```

次のような感じに翻訳される。

```python
except E as N:
    try:
        foo
    finally:
        del N
```

これが意味するところは、あるexcept節が終わったとき、例外はまた別の名前に割り当てるべきである、ということだ。

次の文章が理解できない。

> Exceptions are cleared because, with the traceback attached to them, they form a reference cycle with the stack frame, keeping all locals in that frame alive until the next garbage collection occurs.

* 上のexcept節は、Pythonではスコープ化されていない。この例における全ての変数は同じスコープにある。そして変数`e`は`except`節の実行により除去される。分離された内部スコープを持つ関数においては、このようなことは起こらない。以下の例はそれを示している：

```python
def f(x):
    del(x)
    print(x)

x = 5
y = [5, 4, 3]
```

**出力**

```python
>>>f(x)
UnboundLocalError: local variable 'x' referenced before assignment
>>>f(y)
UnboundLocalError: local variable 'x' referenced before assignment
>>> x
5
>>> y
[5, 4, 3]
```

* Python 2.xでは変数名`e`は`Exception()`インスタンスに割り当てられる。これを印字しようとすると何も表示されない。

```python
>>> e
Exception()
>>> print e
# Nothing is printed!
```

## どこでreturnしても帰ってくる！

```python
def some_func():
    try:
        return 'from_try'
    finally:
        return 'from_finally'
```

**出力**

```python
>>> some_func()
'from_finally'
```

### 解説

* `return`, `break`または`continue`文が`finally`節をもつ`try`中で実行されたとき、`finally`節も結局実行されることになる。
* 関数の返り値は、最後に実行された`return`文により決定される。`finally`は常に最後に実行されるので、返り値は上述のようになる。

## 真が偽であるとき (Python 2.x系限定)

```python
True = False
if True == False:
    print("I've lost faith in truth!")
```

**出力**

```python
I've lost faith in truth!
```

### 解説

* Pythonは`bool`型を持たない。偽は0, 真は1で表している。`True`と`False`はビルトイン変数なので、後方互換性のため長らく定数化することができなかった。
* Python 3.xではこの問題は解決された。

## 連鎖演算には注意しよう

```python
>>> True is False == False
False
>>> False is False is False
True
>>> 1 > 0 < 1
True
>>> (1 > 0) < 1
False
>>> 1 > (0 < 1)
False
```

### 解説

https://docs.python.org/2/reference/expressions.html#not-in より

> 形式的には、 a, b, c, …, y, z が式で op1, op2, …, opN が比較演算子である場合、 `a op1 b op2 c ... y opN z` は `a op1 b and b op2 c and ... y opN z` と等価になります。ただし、前者では各式は多くても一度しか評価されません。

連鎖演算 (chained operation) を初めて見た人には、上の例はバカバカしく見えるかもしれない。普通は`a == b == c`や`0 <= x <= 100`のように条件文を連鎖するのに使う。

* `False is False is False` は `(False is False) and (False is False)`と同等である。
* `True is False == False`は`True is False and False == False`と同等。`True is False`は`False`, よって式全体は`False`。
* `1 > 0 < 1`は`1 > 0 and 0 < 1`よって全体は`True`と評価される。
* `(1 > 0) < 1`は`True < 1`であり、

```python
>>> int(True)
1
>>> True + 1 #not relevant for this example, but just for fun
2
```

なので`1 < 1`と同等。これは`False`と評価される。

## クラススコープを無視した名前解決

**1**

```python
x = 5
class SomeClass:
    x = 17
    y = (x for i in range(10))
```

**出力**

```python
>>> list(SomeClass.y)[0]
5
```

**2**

```python
x = 5
class SomeClass:
    x = 17
    y = [x for i in range(10)]
```

**出力(Python 2.x)**

```python
>>> SomeClass.y[0]
17
```

**出力(Python 3.x)**

```python
>>> SomeClass.y[0]
5
```

### 解説

* クラス定義の内側でネストしたスコープは、クラスレベルにおける名前束縛を無視する。
* ジェネレータ式はそれ自身でスコープを持つ。
* Python 3.xではリスト内包もスコープを持つ。

## 一度の操作でNoneもなくなる

```python
some_list = [1, 2, 3]
some_dict = {
  "key_1": 1,
  "key_2": 2,
  "key_3": 3
}

some_list = some_list.append(4)
some_dict = some_dict.update({"key_4": 4})
```

**出力**

```python
>>> print(some_list)
None
>>> print(some_dict)
None
```

### 解説

シーケンスの要素を変更するメソッド(`list.append`, `dict.update`, `list.sort`など)はオブジェクトをインプレースに変更し、メソッド自体は`None`を返す。これは無駄なコピーを作らないため、つまりパフォーマンスのためである([参照](https://docs.python.org/ja/3.6/faq/design.html#why-doesn-t-list-sort-return-the-sorted-list))。

## 文字列の明示的な型キャスト

これもWTFではないが、原著者がPythonを始めてから気づくまでけっこう時間がかかったとのこと。

```python
a = float('inf')
b = float('nan')
c = float('-iNf')  #These strings are case-insensitive
d = float('nan')
```

**出力**

```python
>>> a
inf
>>> b
nan
>>> c
-inf
>>> float('some_other_string')
ValueError: could not convert string to float: some_other_string
>>> a == -c #inf==inf
True
>>> None == None # None==None
True
>>> b == d #but nan!=nan
False
>>> 50/a
0.0
>>> a/a
nan
>>> 23 + b
nan
```

### 解説

`inf`と`nan`は特別な文字列である(大文字小文字を区別しない)。`float`型に明示的型キャストを行うと、それぞれ'無限大'と'非数'を表現する値になる。

## クラス属性とインスタンス属性

```python
class A:
    x = 1

class B(A):
    pass

class C(A):
    pass
```

**出力**

```python
>>> A.x, B.x, C.x
(1, 1, 1)
>>> B.x = 2
>>> A.x, B.x, C.x
(1, 2, 1)
>>> A.x = 3
>>> A.x, B.x, C.x
(3, 2, 3)
>>> a = A()
>>> a.x, A.x
(3, 3)
>>> a.x += 1
>>> a.x, A.x
(4, 3)
```

**2**

```python
class SomeClass:
    some_var = 15
    some_list = [5]
    another_list = [5]
    def __init__(self, x):
        self.some_var = x + 1
        self.some_list = self.some_list + [x]
        self.another_list += [x]
```

**出力**

```python
>>> some_obj = SomeClass(420)
>>> some_obj.some_list
[5, 420]
>>> some_obj.another_list
[5, 420]
>>> another_obj = SomeClass(111)
>>> another_obj.some_list
[5, 111]
>>> another_obj.another_list
[5, 420, 111]
>>> another_obj.another_list is SomeClass.another_list
True
>>> another_obj.another_list is some_obj.another_list
True
```

### 解説

* クラス変数とクラスインスタンス中の変数は、内部的にはクラスオブジェクトの辞書として扱われている。もし変数名がそのクラスで見つからなければ、親クラスの変数が探索される。
* `+=`演算子は、可変オブジェクトを新しいオブジェクトを生成することなく、インプレースで変更する。ゆえに、あるインスタンスで変更された属性は、他のインスタンスやクラス属性に影響を及ぼす。

## 例外をキャッチせよ

```python
some_list = [1, 2, 3]
try:
    # This should raise an ``IndexError``
    print(some_list[4])
except IndexError, ValueError:
    print("Caught!")

try:
    # This should raise a ``ValueError``
    some_list.remove(4)
except IndexError, ValueError:
    print("Caught again!")
```

**出力 (Python 2.x)**

```
Caught!

ValueError: list.remove(x): x not in list
```

**出力 (Python 3.x)**

```
  File "<input>", line 3
    except IndexError, ValueError:
                     ^
SyntaxError: invalid syntax
```

### 解説

* except節に複数の例外を付するためには、最初の引数をカッコでかこむ必要がある。第2引数は任意の名前で、例外インスタンスがその名前に束縛される。例：

```python
some_list = [1, 2, 3]
try:
   # This should raise a ``ValueError``
   some_list.remove(4)
except (IndexError, ValueError), e:
   print("Caught again!")
   print(e)
```

**出力 (Python 2.x)**

```
Caught again!
list.remove(x): x not in list
```

**出力 (Python 3.x)**

```
  File "<input>", line 4
    except (IndexError, ValueError), e:
                                     ^
IndentationError: unindent does not match any outer indentation level
```

* 上のエラーから分かるように、カンマで例外とそれを束縛する変数を区切る記法はPython 3では廃止された。正しい書き方は`as`を使う方法である。

```python
some_list = [1, 2, 3]
try:
    some_list.remove(4)

except (IndexError, ValueError) as e:
    print("Caught again!")
    print(e)
```

**出力**

```
Caught again!
list.remove(x): x not in list
```

## 午前0時は存在しない (Python 3.5以前限定)

```python
from datetime import datetime

midnight = datetime(2018, 1, 1, 0, 0)
midnight_time = midnight.time()

noon = datetime(2018, 1, 1, 12, 0)
noon_time = noon.time()

if midnight_time:
    print("Time at midnight is", midnight_time)

if noon_time:
    print("Time at noon is", noon_time)
```

**出力**

```
('Time at noon is', datetime.time(12, 0))
```

午前0時が表示されない。

### 解説

* Python 3.5以前では、`datetime.time`オブジェクトでの午前0時(UTC)のブール値は`False`と判定されていた。これはエラーを起こしやすいということで修正されている。

## ブール値数え上げ

```python
# A simple example to count the number of boolean and
# integers in an iterable of mixed data types.
mixed_list = [False, 1.0, "some_string", 3, True, [], False]
integers_found_so_far = 0
booleans_found_so_far = 0

for item in mixed_list:
    if isinstance(item, int):
        integers_found_so_far += 1
    elif isinstance(item, bool):
        booleans_found_so_far += 1
```

**出力**

```python
>>> booleans_found_so_far
0
>>> integers_found_so_far
4
```

### 解説

* ブール型は`int`のサブクラスである。

```python
>>> isinstance(True, int)
True
>>> isinstance(False, int)
True
```

* [Stack Overflowのこの解答](https://stackoverflow.com/a/8169049/4354153)も参照。

## カッコの無駄骨

```python
t = ('one', 'two')
for i in t:
    print(i)

t = ('one')
for i in t:
    print(i)

t = ()
print(t)
```

*出力*

```python
one
two
o
n
e
tuple()
```

`('one')`はタプルになることを期待していた。どうしたらできるか？

### 解説

* `t = ('one',)`あるいは`t = 'one',`でできる。
* 単体の`()`は`tuple`を表す特別な構文である。

## 変更から回復するループ変数

```python
for i in range(7):
    print(i)
    i = 10
```

**出力**

```python
0
1
2
3
4
5
6
```

ループが一度しか実行されない、とか思わなかっただろうか。

逆にこのループが正常に実行されるのはなぜか。

### 解説

* ソース：https://docs.python.org/3/reference/compound_stmts.html#the-for-statement
* 代入`i = 10`はループの反復にまったく影響を与えない。全てのイテレーションが始まるまえに、次の要素がイテレータ(この場合`range(7)`)から供給され、目的のリスト変数(`i`)に代入が行われる。

## これの動作、予想できるかな？

```python
a, b = a[b] = {}, 5
```

**出力**

```python
>>> a
{5: ({...}, 5)}
```

### 解説

* [Python言語リファレンス](https://docs.python.org/ja/3.6/reference/simple_stmts.html#assignment-statements)によると、代入文は次の構造を持っている：

```
(target_list "=")+ (expression_list | yield_expression)
```

そして

> 代入文は式のリスト (これは単一の式でも、カンマで区切られた式リストでもよく、後者はタプルになることを思い出してください) を評価し、得られた単一の結果オブジェクトをターゲット (target) のリストに対して左から右へと代入してゆきます。

* `target_list "=")+`における`+`は1つ以上のターゲットリストが存在することを意味している。上のコードの場合、ターゲットリストは`a`, `b`そして`a[b]`である（対して式リストは厳密に1つだけである。このケースでは`{}, 5`がそれだ）。
* 式リストが評価されると、その値は**ターゲットリストの左から右へ**アンパックされる。このケースでは、タプル`{}, 5`は`a, b`にアンパックされ、`a = {}`, `b = 5`となる。
* `a`に`{}`は代入されており、`{}`は可変リストである。
* 左から2番目のターゲットリストは`a[b]`である（ここまでの知識がなければ、これは`a`も`b`も宣言していないのでエラーになると推測されるかもしれないが、`a`と`b`には確かに値が代入されている）。
* いま、辞書のキー`5`を`({}, 5)`にセットして、循環参照を生成する(出力中の`{...}`は`a`が参照しているオブジェクトと同じものを参照している)。よりシンプルな循環参照の例を挙げると：


```python
>>> some_list = some_list[0] = [0]
>>> some_list
[[...]]
>>> some_list[0]
[[...]]
>>> some_list is some_list[0]
[[...]]
```

これは最初の例と似通っている(`a[b][0]`は`a`と同じオブジェクト)

* 簡単にすると、コードを次のように腑分けすることができる。

```python
a, b = {}, 5
a[b] = a, b
```

循環参照であることは`a[b][0]`が`a`と同じオブジェクトであることから確かめられる。

```python
>>> a[b][0] is a
True
```
