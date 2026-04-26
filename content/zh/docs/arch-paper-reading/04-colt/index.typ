#import "../../index.typ": (
  doc-toc, series-context, series-navbar, template, tufted,
)
#import "../series.typ": arch-paper-reading-series
#show: template.with(
  locale: "zh",
  route: "docs/arch-paper-reading/04-colt/",
  title: "CoLT",
)

#let series = arch-paper-reading-series
#let nav = series-context(series, "docs/arch-paper-reading/04-colt/")
#let paper = "/assets/papers/arch-paper-reading/colt.pdf"

= CoLT: Coalesced Large-Reach TLBs

#series-navbar("zh", nav)

#doc-toc("zh")

原论文：#link(paper)[CoLT: Coalesced Large-Reach TLBs (PDF)]

TLB miss 很贵，而传统的 superpage/huge page 虽然能扩大 TLB coverage，但要求操作系统拿出“大块、连续、对齐”的物理页，还会带来额外管理成本、碎片问题和 I/O 开销。作者的核心观察是，操作系统其实经常会自然地产生一种没大到能做 superpage、但也不小的连续性，也就是多个连续虚拟页正好映射到多个连续物理页，规模常常是几十页。这类连续性对 superpage 来说不够，但对 TLB 来说已经很有价值了。

== 它真正利用的是“几十页连续”，不是“大页”

CoLT 的核心想法是*把多个连续的 4KB 映射压成一个 TLB 项*。论文把这个叫 *coalescing*。我们可以把它理解成：页表里仍然是普通 base pages，OS 也不用真的构造 huge page；只是当硬件发现一串连续的 VPN -> PPN 映射时，就在 TLB 里把它们合并表示。这样做的目标是扩大 TLB 的 reach，但避免 superpage 的重负担。

论文的引言中有两个regime的关键对比：
- *superpage regime*: 需要几百个连续 4KB 页，比如一个 2MB page 需要 512 个连续 4KB 页，而且还要对齐。
- *intermediate contiguity regime*: 通常只有几十页连续，达不到 superpage 门槛，但已经足够让一个 TLB entry 覆盖更多地址。
  - 在默认 Linux 设置下，作者测到平均 contiguity 大约是 41 页。就算关掉 THS，平均也还有大约 18 页。即使在更差的配置下，平均也还有大约 15 页左右。

这篇论文就是承认现实里的连续性通常没那么完美，然后为这种不完美连续性设计 TLB.

#figure(
  image("imgs/colt-topology.svg"),
  caption: [`CoLT` 的拓扑图这次改成了上下两段：上面是 fill-time coalescing，把 page walk 顺手带回来的 translation run 压成 `CoLT-SA` 或 `CoLT-FA` entry；下面是 hit-time expansion，后续请求只消费已经做好的 metadata。重点是复杂度被明确压在 fill path 上。],
)

== 为什么 OS 会自然产生contiguity

作者定义的 *page allocation contiguity* 是连续的虚拟页对应到连续的物理页框

```
VPN -> PFN
VPN+1 -> PFN+1
VPN+2 -> PFN+2
VPN+3 -> PFN+3
...
```

比如：虚拟页 1, 2, 3 映射到物理页框 58, 59, 60，这就是一个 3-page contiguity。

这种连续性和 superpage 有两个关键区别：
1. superpage 要求固定且很大的连续度。比如 2MB huge page 需要 512 个连续 4KB 页。而 CoLT 不要求必须512页, 几十页也有价值.
2. superpage 还要求对齐。不只是连续，还得起始地址对齐到 superpage 大小边界。而 CoLT 不要求对齐, 只要连续就行.

所以contiguity从哪儿来呢?

=== Buddy allocator 会天然制造 contiguity

buddy allocator 把空闲物理页按 $2^k$ 大小分组管理。如果应用一次性申请 N 页，OS 会尽量从某个连续块里切出一段给它。

论文中给的例子很典型, 假设空闲页框里有 4,5,6,7 这 4 个连续页。如果应用要 2 页，allocator 可以把 4,5,6,7 一分为二：
- 把 4,5 分给应用，
- 把 6,7 放回 free list。

这个分配过程本身就在偏向连续物理页。很多应用不是一次只要 1 页，而是 malloc 一个较大的对象，背后会请求多个页。于是 buddy allocator 往往会把这些页成块地分出去。

=== Memory compaction 会把碎片重新整理出连续空洞

当系统碎片严重时，Linux 的 memory compaction daemon 会做两件事：
1. 从低地址开始找“可移动”的已分配页。大多数用户态页是可移动的，内核页和 pinned 页往往不可移动。
2. 从高地址开始找空闲页。然后系统把可移动页搬过去，尽量把空闲空间拼成更大的连续块。

所以 compaction 会把散落的空闲页攒成连续空闲页。这对 buddy allocator 很有帮助，因为 buddy allocator 最喜欢从连续大块里切页。

有compaction的情况下*系统负载变高，不一定让 contiguity 变差，反而有时会变好。*因为负载高、碎片多，会更频繁地触发 compaction；compaction 反过来又造出了更多连续空闲块；于是后续分配时可能拿到更连续的 PFN。

=== THS 即使没成功维持 huge page，也会留下‘残余连续性’

Transparent Hugepage Support，简称 THS，本来是想尽量构造 2MB huge page 的。但现实里它经常做不到，或者做成了之后又因为系统压力被拆回 4KB 页。表面上这好像说明 THS 失败了。但作者的观察到即使 huge page 最后没保住，它的努力也没白费：
1. 它尝试过把一大片页凑连续。所以即便后来拆了，拆出来的 4KB 页之间往往仍然保持几十页级别的连续性。
2. THS 本身依赖 compaction。所以开启 THS 往往会更频繁地促发 compaction，进一步提高 contiguity。

THS 对 CoLT 来说，即使失败，也会留下可以 coalesce 的连续 base pages。

== CoLT 到底怎么利用这些 contiguity

这里作者提出了三个统一原则：
1. 识别连续的 virtual-to-physical translations。也就是发现一串 VPN -> PPN 是按顺序增长的。
2. 只在 TLB miss 时 coalesce。在 miss 触发 page walk 后，*顺手检查*周围翻译项能不能合并。
3. 不走激进 speculation / prefetch 路线。作者不想额外建一堆投机结构，也不想因为错猜把 TLB 污染掉。

CoLT 到底怎么做 coalescing？SA、FA、All 三种方案差在哪？

=== CoLT-SA：在 set-associative TLB 里做 coalescing

TLB 和 cache 很像，也常见三种组织方式：

1. Fully associative: 任何一个虚拟页号都可以放进 TLB 的任意一个条目里。查找时要和所有条目比。
  - 优点是灵活，冲突少。
  - 缺点是硬件贵，功耗高。
2. Direct-mapped: 每个虚拟页号只能去一个固定位置。
  - 优点是简单快。
  - 缺点是冲突严重。
3. Set-associative 折中方案。先把 TLB 分成很多 set，每个虚拟页号先算出自己属于哪个 set，然后只在那个 set 里面比对若干个条目。

一个 TLB 有 32 entries，是 4-way set associative。那它就有：`32 / 4 = 8 sets` 即:
- 一共有 8 个 set
- 每个 set 里有 4 个 entry
- 一个 VPN 先根据某些 bit 算出它该去哪个 set
- 然后只在那个 set 的 4 个 entry 里做 tag match

假设 TLB 是 8-set，那就需要 `log2(8) = 3` 个 bit 来选 set。如果用 `VPN[2:0]` 作为 set index，那么：
- VPN 末 3 bit 是 `000` 的页，去 set 0
- VPN 末 3 bit 是 `001` 的页，去 set 1
- ...
- VPN 末 3 bit 是 `111` 的页，去 set 7

普通 set-associative TLB 的问题是：连续 VPN 往往会落到连续 set 里，而不是同一个 set。如果不在同一个 set，它们就没法被编码成一个 entry。论文中举例，假设是一个 8-set TLB，正常会用 `VPN[2:0]` 选 set。这样连续的页会落到连续的不同 set 里，就没法用一个 entry覆盖他们, 只能各放各的, 自然没法 coalesce：
- VPN 1000 -> set 0
- VPN 1001 -> set 1
- VPN 1010 -> set 2
- VPN 1011 -> set 3

所以 CoLT-SA 的关键修改是：*改 TLB 的 set index 选取方式。*作者的办法是*把 index bits 左移*。比如改成用 `VPN[4:2]` 来选 set。这样一来，4 个连续的虚拟页会落进同一个 set，于是就有机会被一个 entry 合并表示。

这样一来，连续 4 个页被分散到 4 个不同 set，就没法在一个 entry 里 coalesce。所以 CoLT-SA 改了 index 选法, 改成用更高位，比如 `VPN[4:2]`。这样连续 4 个页的低 2 bit 虽然不同，但 `VPN[4:2]` 一样，于是它们都会落到同一个 set。(但是落到同一个set里面不代表都能合并!只是提高了可以合并的概率.)

==== CoLT-SA 的 entry 怎么表示多个页

作者的做法大致是：
1. 存一个 base PPN: 对应第一个有效 translation 的物理页框号
2. 存一组 valid bits: 表示这 4 个可能位置里哪些真的有效
3. 再存 tag 和属性位: 表示这一坨 coalesced 区间属于哪个 VPN 高位范围

访问时怎么命中？
1. 先用 tag 判断是不是这一大组
2. 再用较低位 VPN 去选 valid bit
3. 如果 valid，就根据“离 base 有多少偏移”算出目标 PPN

也就是说，物理页号`PPN = base_PPN + offset`

==== CoLT-SA的tradeoff

如果 index
- 左移得不够多：明明系统里存在 4 页、8 页这样的连续性，但 set 映射规则把它们拆开了，硬件根本没机会把它们合并掉。连续页很难落到同一个 set，coalescing 机会少。
- 如果左移得太多：太多页挤进同一个 set，conflict miss 会变严重。

所以 CoLT-SA 在做一个很典型的 architecture tradeoff:
1. 让连续页尽量落到同一个 set，这样才有机会被合并成一个 TLB entry。
2. 但又不能让太多页都挤进同一个 set，不然这个 set 的 way 不够，会发生 conflict miss。

论文后面实验给出的结论是允许每项 coalesce 到 4 个 translation，通常是比较好的平衡点。

还是用 4 way 8-set TLB 的例子, 原始`VPN[2:0]`

用 `VPN[3:1]`, 这样连续页的映射会变成:

```
0 -> set 0
1 -> set 0
2 -> set 1
3 -> set 1
4 -> set 2
5 -> set 2
6 -> set 3
7 -> set 3
```

左移不够多的时候, 最多可以把 0,1 合成一个 entry，把 2,3 合成一个 entry。还是不够理想，因为明明这 4 页是连续的，却只能合成两半。

用 `VPN[5:3]`:

```
0 -> set 0
1 -> set 0
2 -> set 0
3 -> set 0
4 -> set 0
5 -> set 0
6 -> set 0
7 -> set 0
```

左移太多又会带来 conflict miss, 这就要看 set-associative 里的 way。

那么连续 8 个页：0,1,2,3,4,5,6,7 -> 全部进 set 0, 这时候会发生两种情况。
- 情况 A：这 8 页真的刚好可以完美 coalesce 成 1 个 entry。那很好，set 0 只占 1 个 way，收益巨大。
- 情况 B：这 8 页并不能完美合并。比如：
  - 0,1 连续
  - 2 不连续
  - 3,4 连续
  - 5 不连续
  - 6,7 连续
  那可能需要 5 个 entry 才能表示这 8 页。但 set 0 只有 4-way，只能放 4 个 entry，放不下的就要挤掉别的 entry。这就是 conflict miss。本来这些页如果分散到多个 set，可能每个 set 都有空位；现在为了 coalescing把它们强行聚到同一个 set，结果 set 里的 way 不够用了，发生互相驱逐。

==== 为什么作者只检查最多 8 个相邻 translation

TLB miss 后会发生 page walk。作者不想为了 coalescing 再多做额外的 page walk，那样太贵。

page table entry 从 LLC 取回来时，是按 cache line 拉的。一个 64B cache line 里大概能带回 8 个 PTE。既然这些 PTE 已经免费带回来了，那我就只检查这 8 个里有没有连续性。

这把额外开销压得很低，同时把最大 coalescing 长度也限制到了 8。

=== CoLT-FA：把连续翻译写成短范围

前面的 `CoLT-SA` 还在 set-associative TLB 的框架里工作：连续页本来会被 set index 打散，所以它通过移动 index bits，让相邻 translation 更容易落到同一个 set，再用 valid bits 表达这一簇里哪些页被覆盖。

`CoLT-FA` 换了一个表达方式。它不再围着 set mapping 打转，而是直接把一段连续 base-page translation 当成短范围存下来。论文里这个 fully-associative 结构通常借用 superpage TLB 的位置，只是 entry 不再只表达巨大、固定对齐的 superpage，也可以表达一小段连续 4KB page。

它的 entry 大致包含：
- `base VPN`
- `coalescing length`
- `base PPN`
- 共享权限和属性位

命中时也不再问“set 里的哪一个 valid bit 对上了”，而是问请求 VPN 是否落在这个短范围里：

```text
base_VPN <= req_VPN < base_VPN + length
PPN = base_PPN + (req_VPN - base_VPN)
```

所以 `CoLT-FA` 更像一个小的 range TLB。它的好处是不用强迫这些页落在同一个 set；代价是 fully-associative compare、range check 和偏移加法都比 `CoLT-SA` 更重。

==== 一个具体例子

假设 miss 时发现：
- `VPN 100` -> `PPN 500`
- `VPN 101` -> `PPN 501`
- `VPN 102` -> `PPN 502`
- `VPN 103` -> `PPN 503`

`CoLT-FA` 可以把它们压成：
- `base VPN = 100`
- `length = 4`
- `base PPN = 500`

以后查 `VPN 102` 时，只要判断 `102` 落在 `[100, 104)` 里，再算出偏移 `2`，就能返回 `PPN = 500 + 2 = 502`。

=== 两种 entry 的差别

我觉得最稳的记法是：
- `CoLT-SA`: coverage 被编码进 `valid bits`
- `CoLT-FA`: coverage 被编码进 `base VPN + length`

`SA` 版本更像“set 内一簇”，便宜一些，但容易受 set 冲突影响。`FA` 版本更像“一个短范围”，灵活一些，但 hit path 和 fill path 都更重。

#figure(
  image("imgs/colt-structures.svg"),
  caption: [`CoLT` 的两种 entry 放在一起看会更清楚：`SA` 把 coverage 写进 `valid bits`，`FA` 把 coverage 写成 `base VPN + length`。同样是“一个 entry 覆盖多个 base page”，只是一个偏 set-local，一个偏 range-like。],
)

=== CoLT-All：组合不等于收益相加

论文还讨论了一个更贪心的版本，通常叫 `CoLT-All`：`SA` 能吃的连续性也吃，`FA` 能吃的连续性也吃。这个版本直觉上很诱人，但它最容易让人误以为两个结构的收益可以线性相加。

真实情况没那么简单。因为同一段连续性到底先被谁消费，会改变后面的机会。一段 8 页连续映射，也许本来能在 `FA` 里作为一个完整范围出现；如果先被 `SA` 吃掉一部分，`FA` 剩下的未必还能拼成原来的范围。反过来，如果先塞进 `FA`，也可能减少 `SA` 那边某些局部 coalescing 的机会。

再加上两个结构容量不同、冲突行为不同、命中路径复杂度不同，最后就不是“1 + 1 = 2”。`CoLT-All` 值得看的地方就在这里：architecture 里把两个好东西拼在一起，不代表收益天然可加。

== 设计取舍：把重活压到 fill path

读到这里，`CoLT` 最值得记住的已经不是 `SA` 或 `FA` 某一种 entry，而是复杂度应该放在哪条路径上。作者的判断非常明确：TLB hit path 太敏感，不能乱堆聪明逻辑；真正重的 coalescing 检测和 entry 构造，尽量放到 miss / fill path。

=== fill path：只吃这次 miss 顺手带回来的连续性

一次 TLB miss 后，硬件大致会这样走：

1. L1 / L2 TLB miss。
2. 触发 page walk。
3. page walk 把目标 PTE 带回来，当前 miss 先被满足。
4. 同时，硬件检查这次已经顺手拿回来的相邻 PTE。
5. 如果它们满足虚页连续、物理页连续、权限和属性一致，就压成 coalesced entry。
6. 最终把结果写回 `SA` 或 `FA` 结构。

这里的关键不是“它能不能做 coalescing”，而是“它只用这次 miss 已经顺手带回来的材料做 coalescing”。page walk 从 LLC 拉回 PTE 时，本来就是按 cache line 拿的；一个 `64B` cache line 里大概能放 `8` 个 PTE。作者于是只检查这 `8` 个左右的相邻 translation，不为了更长 coverage 主动发额外 page walk。

这个限制看起来保守，但它把成本锁得很清楚：
- 不额外增加 page walk 数量
- 不额外引入很长的 refill 扫描
- 最大 coalescing 长度自然被限制在合理范围内

`CoLT-FA` 在 fill path 上还能更进一步。新 entry 生成后，它可能和已有 resident FA entry 继续 merge。这样可以拼出更长的范围，但代价也很明确：灵活性是拿 fill path 复杂度换的。

#figure(
  image("imgs/colt-update-flow.svg"),
  caption: [`CoLT` 最值得看的是 fill 流。miss 触发 walk，walk return bundle 再交给 contiguity detector 和 entry builder，最后生成 `SA / FA` 形式的 refill 结果。真正重的检测、拼接、筛条件，都被压在这里。],
)

=== hit path：只消费已经做好的 metadata

把重活搬到 fill path 后，hit path 就应该尽量简单。

`CoLT-SA` 命中时大致是：
1. 用改过的 index bits 访问 set。
2. 做 tag match。
3. 用低位 VPN bits 选择 valid-bit 对应的位置。
4. 根据槽位偏移恢复 `PPN`。

`CoLT-FA` 命中时更像：
1. fully-associative compare。
2. 看请求 VPN 是否落在 entry 范围内。
3. 计算 `req_VPN - base_VPN`。
4. 再把偏移加到 `base_PPN`。

所以 `SA` 是低成本方案，`FA` 是高灵活方案。整篇 paper 的一个反复出现的原则就是：hit path 上只做必要的 compare、bit select、offset add；发现连续性、决定怎么合、能不能继续拼，全部留到 fill path。

=== 现实边界：不是地址连续就能合

`CoLT` 一开始就承认自己有边界，而且这些边界不是缺陷，而是设计选择。

第一，translation attribute 必须一致。即使虚页和物理页都连续，如果权限、cacheability 或其他属性不同，也不能安全地共享一个 coalesced entry。coalescing 不是“地址连续就行”，而是 translation semantics 也必须一致。

第二，invalidation 更偏粗粒度。一旦某个 coalesced entry 里的一页发生 shootdown / invalidation，最简单可靠的办法往往是整条 coalesced entry 作废。理论上可以做更细粒度拆分，但那会让 invalidation 逻辑更复杂，也更难验证。

第三，不额外发 page walk。这等于给 `CoLT` 的野心画了边界：它只吃顺手拿到的 contiguity，不为了更多 coverage 去额外制造 page walk 流量。所以它不会变成一个 TLB 版激进预取器。

== 结果：中等连续性确实能换成 TLB reach

如果只盯最终性能增益，会错过这篇 paper 最重要的结论。它先证明现实系统里真的存在 intermediate contiguity，再证明这段连续性能被硬件换成有效的 TLB reach。

第一层结论是，现实里有很多“做 superpage 不够，但做 TLB coalescing 已经够用”的连续性。默认 Linux 设置下，作者测到平均 contiguity 大约在几十页量级；关掉 `THS` 后会下降，但不会归零；更悲观的配置下，也还有十几页量级。

第二层结论是，这段连续性确实能减少 TLB miss。论文结果大意是，`CoLT-SA` 就能消掉很大一块 TLB miss，量级大约四成；`CoLT-FA` 和更激进的组合版本能推到五成多；整体性能收益大约在一成出头。

最值得看的不是精确到小数点后的百分比，而是这个判断：不用真的构造 huge page，只靠中等连续性，也已经足够让 TLB 行为明显变好。它把“扩大 TLB reach”从一个严重依赖 OS 和理想物理连续性的任务，拉回到了一个硬件更可控的范围内。

#series-navbar("zh", nav)
