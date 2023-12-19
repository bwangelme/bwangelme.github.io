---
title: "Latency"
date: 2023-12-19T18:51:09+08:00
lastmod: 2023-12-19T18:51:09+08:00
author: "bwangel"
---

Latency Comparison Numbers (~2012)
----------------------------------

Operation|ns|µs|ms|note
---|---|---|---|---
L1 cache reference|0.5 ns|||
Branch mispredict|5 ns|||
L2 cache reference|7 ns|||14x L1 cache
Mutex lock/unlock|25 ns|||
Main memory reference|100 ns|||20x L2 cache, 200x L1 cache
Compress 1K bytes with Zippy|3,000 ns|3 µs||
Send 1K bytes over 1 Gbps network|10,000 ns|10 µs||
Read 4K randomly from SSD*|150,000 ns|150 µs||~1GB/sec SSD
Read 1 MB sequentially from memory|250,000 ns|250 µs||
Round trip within same datacenter|500,000 ns|500 µs||
Read 1 MB sequentially from SSD*|1,000,000 ns|1,000 µs|1 ms|~1GB/sec SSD, 4X memory
Disk seek|10,000,000 ns|10,000 µs|10 ms|20x datacenter roundtrip
Read 1 MB sequentially from disk|20,000,000 ns|20,000 µs|20 ms|80x memory, 20X SSD
Send packet CA -> Netherlands -> CA|150,000,000 ns|150,000 µs|150 ms|

Notes
-----
- 1 ns = 10^-9 seconds
- 1 us = 10^-6 seconds = 1,000 ns
- 1 ms = 10^-3 seconds = 1,000 us = 1,000,000 ns

Credit
------
- By Jeff Dean:               http://research.google.com/people/jeff/
- Originally by Peter Norvig: http://norvig.com/21-days.html#answers

Contributions
-------------
- 'Humanized' comparison:  https://gist.github.com/hellerbarde/2843375
- Visual comparison chart: http://i.imgur.com/k0t1e.png
