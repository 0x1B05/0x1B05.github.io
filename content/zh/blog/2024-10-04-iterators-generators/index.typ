#import "../index.typ": template, tufted
#show: template.with(
  locale: "zh",
  route: "blog/2024-10-04-iterators-generators/",
  title: "Python 中的迭代器与生成器",
)

= Python 中的迭代器与生成器

Python 的迭代协议是写出高效、符合 Python 风格代码的基础。#footnote[迭代器协议在 Python 2.2（2001）中作为 PEP 234 的一部分引入。] 虽然迭代器和生成器关系紧密，但理解它们之间的差异，能帮助你在不同场景中做出更合适的选择。

== 什么是迭代器

凡是实现了 `__iter__()` 与 `__next__()` 方法的对象，都可以被视为迭代器。#footnote[_iterable_ 在调用 `__iter__()` 后返回迭代器，而真正的 _iterator_ 会从 `__iter__()` 返回自身，并通过 `__next__()` 按次产出值。] 当你遍历列表或元组时，Python 会在后台创建一个迭代器。你也可以通过自定义类来手动实现这一协议。

```python
class Counter:
    def __init__(self, max):
        self.max = max
        self.current = 0

    def __iter__(self):
        return self

    def __next__(self):
        if self.current >= self.max:
            raise StopIteration
        self.current += 1
        return self.current
```

== 生成器登场

生成器用函数和 `yield` 关键字，以更简洁的方式创建迭代器。#footnote[Python 还支持形如 `(x * 2 for x in range(10))` 的生成器表达式，它像惰性版的列表推导。] 与其把状态放在类属性里，不如让生成器在多次调用之间自动保存执行位置和局部变量，这通常会让代码更短、更清晰。

```python
def counter(max):
    current = 0
    while current < max:
        current += 1
        yield current
```

这个生成器函数能产出与前面的迭代器类相同的结果，但样板代码要少得多。#footnote[生成器会保存局部变量和执行位置，因此本质上是一种可恢复执行的函数。] 调用生成器函数时，会得到一个已经实现了迭代器协议的生成器对象。

== 内存效率

迭代器和生成器都采用惰性求值：只有在需要时才产生下一个值，而不是一次性把所有数据放进内存。#footnote[`itertools` 模块提供了 `count()`、`cycle()` 等函数来创建无限迭代器。] 因此它们非常适合处理大规模数据集，甚至无限序列。一个生成十亿个数字的生成器只占用很少内存，而十亿个元素的列表往往会直接耗尽机器资源。

#figure(image("imgs/python.webp"), caption: [四个人抬着一条很长的蟒蛇])

== 什么时候用哪一个

在日常开发里，大多数情况下优先使用生成器，因为它更短也更好读。只有当你需要复杂状态管理、多个迭代接口，或一个可复用且行为更丰富的对象时，再考虑写自定义迭代器类。

理解这两种工具，会让你更容易写出优雅而高效的 Python 代码。
