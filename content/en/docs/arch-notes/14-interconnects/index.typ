#import "../../index.typ": (
  definition, doc-toc, example, note, series-context, series-navbar,
  template, tip, warning,
)
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#import "../_diagrams/interconnects.typ": direct-network, mecs-topology
#show: template.with(
  locale: "en",
  route: "docs/arch-notes/14-interconnects/",
  title: "Interconnection Networks",
)

#let series = arch-notes-series
#let nav = series-context(series, "docs/arch-notes/14-interconnects/")

= Interconnection Networks

#series-navbar("en", nav)

#doc-toc("en")


== Communication as a First-Class Resource

An interconnection network is the communication substrate between components
that produce, consume, or store data. It connects processors to processors,
processors to cache banks and memory controllers, cache banks to one another,
and I/O devices to the rest of the system. A network may be a few wires in a
small microcontroller, a board-level fabric, a package link, or a network of
routers on a many-core chip.

Communication is not an afterthought to computation. The interconnect affects:

- *Scalability*: how many endpoints can be connected, and how easily another
  endpoint can be added.
- *Latency and throughput*: how quickly a request reaches its destination and
  how many transfers can overlap.
- *Energy and area*: wires, repeaters, switches, queues, and arbitration logic
  consume physical resources even when the arithmetic units are idle.
- *Reliability*: a link or router fault must not silently lose a coherence,
  memory, or I/O message.
- *Isolation and predictability*: traffic from one application can delay
  another, so quality-of-service (QoS) and fairness may matter as much as
  average bandwidth.

The useful abstraction is a path of shared resources. A packet competes for
each resource along its route; the resulting queueing and flow control are part
of the system's performance, not merely implementation details.

#figure(
  table(
    columns: (1.25fr, 1.4fr, 1.35fr, 1.4fr, 1.25fr),
    inset: 6pt,
    align: center + horizon,
    stroke: 0.45pt,
    [*Endpoint*], [*Network interface*], [*Router*], [*Link*], [*Endpoint*],
    [Core/cache], [request/packetize], [route + arbitrate], [wires], [Memory/I/O],
  ),
  caption: [A network interface decouples an endpoint from the routers and links that carry its messages.],
)

== Vocabulary and Scope

The same word is sometimes used for a physical wire, a logical flow, and a
unit of buffering. Keeping the terms separate makes a design discussion much
less ambiguous.

#three-line-table(
  columns: (1.35fr, 2.35fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Term* | *Meaning* | *Typical design question* |
  | :----- | :------ | :----------------------- |
  | Endpoint | A client of the network, such as a core, cache bank, memory controller, accelerator, or I/O device | What messages does the client generate and consume? |
  | Network interface (NI) | Logic that translates client requests into network packets and turns arrivals back into responses | Where are queues, protocol state, and backpressure kept? |
  | Node | A router/switch location in the topology; in a direct network it may also host an endpoint | Which neighbors and local resources are attached? |
  | Router / switch | A device that selects an output for traffic arriving on an input; a router usually uses packet destination information | How many input/output ports and pipeline stages are affordable? |
  | Link | A physical bundle of wires between two neighboring devices | What are its width, delay, direction, and energy per transfer? |
  | Channel | One logical connection over a link; a physical link can carry multiple virtual channels | How is bandwidth shared and how is availability advertised? |
  | Message | A transfer as seen by the client protocol, for example a cache request plus response | What ordering, reliability, or atomicity does the protocol require? |
  | Packet | The network's independently routed unit; a message can be split into one or more packets | What header and payload must travel together? |
  | Flit | A flow-control digit, the smallest unit that occupies a buffer or link in a wormhole network | Can the router forward this unit without storing the whole packet? |
  | Virtual channel (VC) | A separately queued logical channel sharing one physical channel | Can independent packets make progress without head-of-line blocking? |
  | Radix / degree | Number of ports or neighbors at a router (including or excluding the local port by convention) | Does a larger radix reduce hops enough to justify a larger crossbar? |
]

In a *direct* network, endpoints sit at the router nodes; a mesh is the usual
example. In an *indirect* network, endpoints connect to a separate switching
fabric; a multistage network and a standalone crossbar are examples. A
network's *topology* is the wiring graph. Its *routing algorithm* chooses a
path in that graph, while *switching* and *flow control* determine when the
path's resources can be used.

=== A Small Direct Network

#figure(
  html.frame(direct-network()),
  caption: [A processing element (PE) reaches a direct network through its network interface (NI); each R is both a router and a possible endpoint location.],
)

== Topology Metrics

Topology is the graph-level choice that bounds what routing and arbitration can
achieve. Let a route contain $H$ links, and let each link have bandwidth $b$.
Useful metrics include:

- *Routing distance* (or hop count): the number of links on a selected route.
  It is a property of a route, not just of a pair of endpoints.
- *Diameter*: the maximum shortest-path distance between any two endpoints.
  A large diameter creates a long worst-case path even when local traffic is
  cheap.
- *Average distance*: the mean hop count over the traffic pairs of interest.
  The uniform all-pairs average can be misleading for a workload with strong
  locality.
- *Bisection bandwidth*: cut the network into two equal parts and sum the
  bandwidth of the smallest set of links crossing the cut. With uniform links,
  it is `(minimum crossing channels) * (bandwidth per channel)`. It is most
  meaningful for recursive, symmetric topologies and does not by itself model
  switch contention, routing, or execution time.
- *Path diversity*: the number of distinct useful routes between two endpoints.
  Diversity can spread load and route around faults, but increases routing and
  deadlock-avoidance complexity.
- *Blocking*: a network is non-blocking if every source-to-destination
  permutation can be connected simultaneously. A rearrangeable non-blocking
  fabric can realize every permutation after rearranging existing connections;
  a blocking fabric cannot realize some permutations regardless of routing.
- *Cost and layout*: count links, wire length, switch radix, crossbar entries,
  buffers, repeaters, and control state. A topology that looks cheap in graph
  notation can be difficult to place and time on a real substrate.

#three-line-table(
  columns: (1.25fr, 1.2fr, 1.15fr, 2.6fr),
  inset: 5pt,
  align: left,
)[
  | *Family* | *Typical cost* | *Distance* | *Characteristic tradeoff* |
  | :------- | :------------- | :-------- | :------------------------ |
  | Bus | $O(1)$ shared medium | one arbitration domain | Very simple and useful for a few clients; electrical loading and contention make bandwidth saturate quickly. |
  | Point-to-point / complete graph | $O(N^2)$ links | one hop | Lowest contention and latency when cost is unconstrained; wiring and port count do not scale. |
  | Crossbar | $O(N^2)$ switch fabric | one switch traversal | Non-blocking concurrent transfers to distinct outputs; expensive arbitration and crossbar area. |
  | Multistage (Omega, butterfly, delta, Benes) | commonly $O(N log N)$ | $O(log N)$ stages | Logarithmic cost and latency, but internal paths can block and a simple fabric may have a single route. |
  | Ring | $O(N)$ links | $O(N)$ worst case | Cheap and easy to wire; constant bisection bandwidth and long paths. |
  | Mesh | $O(N)$ links | $O(sqrt(N))$ in a 2-D square | Regular layout and many local paths; edge nodes have fewer neighbors and lower bisection bandwidth. |
  | Torus | $O(N)$ links | $O(sqrt(N))$ in a 2-D square | Wrap-around links equalize edge behavior and raise path diversity; links are longer and layout is harder. |
  | Tree / fat tree | $O(N)$ to more heavily replicated | $O(log N)$ | Good locality and hierarchy; the root or upper links can bottleneck, so fattening upper levels costs area. |
  | Hypercube | $O(N log N)$ links | $O(log N)$ | Many dimensions and low diameter; awkward two-dimensional placement and high router radix. |
]

The asymptotic labels hide constants. A 64-node mesh with short wires can beat
a theoretically lower-diameter fabric if the latter needs a large, slow switch
or long global links. Topology, routing, flow control, and traffic pattern
must therefore be evaluated together.

== Topology Families

=== Bus and Point-to-Point Wiring

A bus attaches every endpoint to one shared link. Arbitration serializes
transfers, which makes ordering and snooping-based coherence easy to implement.
The same shared medium becomes the bottleneck as more clients inject traffic:
electrical loading reduces clock frequency, and one busy sender can delay every
other sender.

At the opposite extreme, a complete point-to-point graph gives every pair an
isolated link. It has excellent latency and little contention, but each node
needs $O(N)$ ports and the system needs $O(N^2)$ links. The physical wiring,
power, and verification cost usually dominate long before the graph is large.

=== Crossbar

A crossbar has an input for each source and an output for each destination.
Each input can connect to one output in a cycle, and non-conflicting transfers
can proceed concurrently. It is attractive for a small core-to-cache-bank
fabric, where low latency and high bandwidth justify the $O(N^2)$ switch and
arbitration logic.

An input-buffered crossbar needs queues at the input (often per VC) and an
output arbiter. A buffered crossbar can hold variable-size packets and absorb
temporary contention. A bufferless crossbar is smaller in storage and can be
adequate when the producer already controls packet timing, but it must either
stall or deflect a conflicting transfer.

=== Multistage Logarithmic Networks

An indirect multistage network connects layers of small switches, commonly
2-by-2 elements. A source crosses $log_2(N)$ stages, reducing the switch cost
from a full crossbar to roughly $O(N log N)$. Omega, butterfly, delta, Banyan,
and Benes are related families with different path multiplicity and blocking
properties.

In a *circuit-switched* multistage fabric, configuration bits establish a
complete source-destination path before data flows. In a *packet-switched*
fabric, each small router arbitrates each packet as it reaches a stage. The
same graph can support either discipline; switching is a protocol choice above
the topology.

=== Combining Operations in an Omega Network

A multistage network can do more than forward packets. In the NYU
Ultracomputer example, an Omega-network switch combines concurrent
`fetch-and-add(M, I)` requests that target the same memory word. Rather than
sending every request to memory, the switch forwards one request whose
increment is the sum of the merged increments. Memory performs one atomic
update and returns the old value; the reverse path adds the appropriate prefix
sum so that every requester receives the value it would have obtained from a
serialized sequence of atomic operations.

This *in-network combining* reduces traffic and synchronization latency for
shared counters, work allocation, and barrier-like operations. It also turns
the switches into protocol participants: they need matching and temporary
state, must preserve the atomic operation's return semantics, and must recover
correctly if a request or response is retried.

=== Ring and Hierarchical Ring

Each ring node has two neighbors. A unidirectional ring sends traffic in one
direction and has average distance near $N/2$; a bidirectional ring can select
the shorter direction or use multiple rings. Rings have $O(N)$ wiring cost and
are attractive when node count and bandwidth demands are moderate, but a cut
through the ring exposes only a constant number of links, so bisection
bandwidth does not grow with $N$.

A hierarchical ring groups nearby nodes into local rings and connects groups
with a higher-level ring. Most traffic stays local while distant traffic uses
the hierarchy. The added gateways and arbitration improve scalability, at the
cost of more complex routing and possible hot spots at the group boundaries.

A *mostly-bufferless hierarchical ring* applies deflection routing at these
boundaries. A packet that cannot transfer from a local ring to the global ring
continues around the ring instead of occupying a large gateway queue; a small
transfer buffer absorbs only the cases whose repeated deflection would cost
more than storage. Local traffic stays on short, cheap rings, while global
traffic pays one or more transfer points. The design saves buffer power and
area, but must guarantee that a packet eventually wins a transfer opportunity
and must prevent one busy global ring from starving a local group. This is the
same minimal-buffering principle later used by MinBD, specialized to a
hierarchical topology.

=== Mesh and Torus

A 2-D mesh gives an interior router north, east, south, and west neighbors;
boundary routers have fewer. Its regular, equal-length links are easy to place
on a chip, and multiple shortest paths exist for many source-destination pairs.
For a square mesh with $N$ nodes, the diameter and average distance scale as
$O(sqrt(N))$.

A 2-D torus adds wrap-around links so every node has the same number of
neighbors. It removes the edge-versus-center latency difference and raises
bisection bandwidth and path diversity. The wrap-around wires may be long,
requiring careful weaving, repeaters, or a higher metal-layer cost.

=== Tree and Fat Tree

A tree is planar and hierarchical. Leaves can communicate locally with short
paths, but traffic that crosses subtrees converges on upper links and the root.
A *fat tree* replicates or widens links toward the root to preserve aggregate
bandwidth; the Connection Machine CM-5 is a classic packet-switched example.
The hierarchy also provides natural places for multicast, reduction, or
combining operations.

=== Hypercube

An $n$-dimensional hypercube has $N = 2^n$ nodes. Node addresses differ in one
bit along each dimension, so each node has $n = log_2(N)$ neighbors and two
nodes are at Hamming distance equal to the number of differing bits. The
diameter is logarithmic and path diversity is high, but the many dimensions and
links are difficult to embed in a planar chip or board.

=== Express-Cube Families

The *generalized express cube* view starts with a regular mesh and spends a
limited wire budget on concentration, replication, or express channels. These
choices change radix, channel width, and diameter together; comparing only the
number of routers can therefore be misleading.

- *Concentration* attaches several terminals to one router. A local crossbar
  gives fast nearest-neighbor traffic and reduces hop count in proportion to
  the concentration degree, but it needs a larger router and leaves fewer
  inter-router channels.
- *CMesh* combines concentration with a mesh. *CMesh-X2* replicates selected
  links/routers to recover bisection bandwidth and channel width while keeping
  the local crossbar manageable.
- *Flattened Butterfly (FBfly)* replaces multiple mesh stages with high-radix
  row/column connectivity. It can reach any node in about two hops, but a
  $k^2/2$ channel count per row/column and large arbitration logic can leave
  links underutilized.
- *MECS* (described in detail in the QoS section below) uses one-to-many
  multidrop express channels. It keeps a low diameter with fewer, wider,
  better-utilized channels and accepts asymmetric router ports and drop-point
  arbitration.
- *Slim NoC* and related generalized express-cube designs use low-diameter
  express links while limiting buffers and global wires. They are useful when
  energy per hop matters more than strict mesh regularity.

#three-line-table(
  columns: (1.45fr, 1.15fr, 1.15fr, 1.25fr, 2.1fr),
  inset: 5pt,
  align: left,
)[
  | *Topology* | *Nodes* | *Diameter* | *Channels* | *Primary tradeoff* |
  | :--------- | :----- | :-------- | :-------- | :----------------- |
  | CMesh | 64 / 256 | 6 / 14 | 2 | Regular and compact; long paths and lower bisection bandwidth |
  | Flattened Butterfly | 64 / 256 | 2 / 2 | 8 / 32 | Excellent connectivity; high channel count and arbitration cost |
  | MECS | 64 / 256 | 2 / 2 | 4 / 8 | One-to-many reach and good wire use; asymmetric control |
]

The values are an analytical comparison for the concentrated organizations
shown here, not universal constants. The useful design procedure is to
match the topology to the traffic (local, all-to-all, multicast, or shared
resource), then evaluate route contention and energy with the actual router and
flow-control implementation.

== Switching: How a Path Is Used

*Circuit switching* reserves a complete path for a flow. A probe or setup
message configures each switch; data then streams without per-packet
arbitration, and the reserved links are released at the end. It avoids
intermediate buffering and isolates the flow, but setup/teardown costs time and
reserved links cannot serve another flow during the circuit.

*Packet switching* routes each packet (or each flit) as resources become
available. It has no setup handshake, can multiplex short flows, and can choose
different paths for different packets. It must resolve contention, provide
flow control, and usually stores at least part of a packet in routers.

#three-line-table(
  columns: (1.35fr, 2.25fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *Property* | *Circuit switching* | *Packet switching* |
  | :--------- | :------------------ | :----------------- |
  | Allocation | Full path before data | Per packet/flit at each router |
  | Buffering | Often unnecessary once the circuit is set | Used to absorb contention or pipeline a packet |
  | Arbitration | Fast during the data phase; setup is expensive | Repeated dynamic arbitration |
  | Link utilization | Can be low when a reserved flow is idle | Other flows can use a free link |
  | Message size | Handles arbitrary streams naturally | Header overhead and packetization cost |
  | Isolation | Strong while the circuit is held | Requires VCs, priorities, or admission control |
]

=== Packet Format and Contention

A packet commonly contains a *header*, *payload*, and *error code* (for
example, a CRC). The header carries destination, source, packet type, length,
ordering, VC, and protocol-control bits. The payload carries client data. An
error code is often placed at the tail so it can be generated while the packet
leaves the source or traverses a link.

#figure(
  block(
    width: 100%,
    inset: 8pt,
    radius: 2pt,
    stroke: 0.5pt + rgb("#9AA4B2"),
    fill: rgb("#F6F8FB"),
  )[
    `| destination + type + length | payload / data | CRC or error code |`
  ],
  caption: [A generic packet format. A packet may be split into flits for transport, but its header describes the complete packet.],
)

When two packets request the same output in the same cycle, the router can:

- buffer one packet until the output is free;
- drop one packet and rely on retry or end-to-end recovery; or
- *deflect* one packet to a nonproductive output, allowing it to keep moving.

The choice couples correctness, queue storage, latency, energy, and protocol
complexity. Dropping is uncommon for reliable cache traffic unless a recovery
protocol exists; deflection removes input queues but may add hops and receiver
reassembly pressure.

== Routing: Choosing a Path

Routing answers *which* output a packet should take. It is distinct from route
computation (the mechanism used to calculate that answer) and from arbitration
(which of several eligible packets gets the output this cycle).

=== Routing Mechanisms

#three-line-table(
  columns: (1.45fr, 2.2fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Mechanism* | *Operation* | *Tradeoff* |
  | :---------- | :--------- | :--------- |
  | Arithmetic | Derive the next port from source and destination coordinates or address bits | Very small and fast for regular meshes, tori, and hypercubes; less suitable for irregular faults or arbitrary graphs |
  | Source-based | The source places the sequence of output ports in the header; each router consumes one port field | Simple routers and little local state, but headers grow with route length |
  | Table lookup | A destination or flow identifier indexes a routing table that returns an output/VC set | Compact packets and flexible routes, but tables consume storage and require updates |
]

=== Deterministic, Oblivious, and Adaptive Algorithms

- *Deterministic routing* always selects the same path for a given source and
  destination. It is easy to verify and reproduce, but cannot exploit path
  diversity or avoid a congested link.
- *Oblivious routing* may choose among several paths, but the choice does not
  inspect current network state. Randomized choices can balance expected load
  while keeping router state simple.
- *Adaptive routing* observes local or global state, such as downstream buffer
  occupancy, outstanding credits, faults, or measured latency, and chooses a
  route accordingly. It can avoid hot spots, but the additional choices must be
  constrained so they do not introduce deadlock or livelock.

The terms *minimal* and *non-minimal* describe path length, not adaptivity.
A minimal path never increases the shortest-path distance to the destination.
A non-minimal path may take a detour to escape congestion or balance load.
Minimal adaptive routing is cheaper and bounds latency, but its productive
outputs may all be busy. Fully adaptive non-minimal routing has more freedom at
the cost of extra hops and a proof or mechanism for forward progress.

=== Dimension-Order (XY) Routing

For a 2-D mesh, *dimension-order routing* (DOR) consumes all displacement in
one dimension before moving in the next. In the common *XY routing* convention,
the packet first moves east or west until its $x$ coordinate matches the
destination, then moves north or south until its $y$ coordinate matches. A
router can compute this using coordinate subtraction; no table is needed.

XY is deterministic, minimal, and easy to pipeline. More importantly, its
resource dependencies are ordered: a packet holding an X-direction channel
cannot request a Y-direction channel in a way that closes a cycle. Thus XY is
deadlock-free in the basic mesh model. The same restriction can create hot
links and leaves alternative shortest paths unused. Tori need a tie-breaking
rule for wrap-around directions, and a faulty link requires a reconfigured
route or a different algorithm.

=== Valiant's Oblivious Routing

Valiant routing balances load by choosing an intermediate node $I$ (often
randomly), routing from source $S$ to $I$, then routing from $I$ to destination
$D$. Each leg can use a deterministic algorithm such as XY:

$ S -> I -> D $

The intermediate hop randomizes otherwise correlated traffic and gives a
universal expected-load bound under common traffic assumptions. The route is
usually non-minimal, so an unloaded network pays extra latency. Practical
variants enable the detour only above a congestion threshold or choose $I$ in
the same quadrant to limit the penalty.

=== Deadlock, Livelock, and Starvation

*Deadlock* is a state with no forward progress because packets hold resources
while waiting for resources held by one another. In a channel-dependency graph,
each directed edge means "a packet holding resource A may request B"; a cycle
is a necessary warning sign for wormhole deadlock.

*Livelock* is different: packets continue moving, but one packet can be
deflected or repeatedly bypassed forever and never reach its destination.
*Starvation* is indefinite postponement caused by an unfair arbiter even when
the route is valid. A design must address all three properties.

#three-line-table(
  columns: (1.55fr, 2.25fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *Technique* | *How it helps* | *Cost or caveat* |
  | :---------- | :------------- | :-------------- |
  | Dimension order / turn model | Prohibit enough turns that channel dependencies have no cycle | Restricts path diversity and may concentrate traffic |
  | Escape virtual channel | Reserve one VC with a known deadlock-free route; ensure every packet can eventually enter it | Uses capacity and needs fair access to the escape VC |
  | Ordered virtual channels | Require requests to move from lower- to higher-numbered VCs (or another acyclic order) | More protocol and VC bookkeeping |
  | Deadlock detection and recovery | Detect a cyclic wait and preempt, drain, or reroute packets | Detection state and recovery latency; preemption must preserve correctness |
  | Age or golden priority | Give the oldest/selected packet a guaranteed service opportunity | Priority metadata and possible loss of throughput fairness |
]

Turn models analyze which directional turns are allowed and remove only the
turns needed to break every cycle. This usually retains more adaptive paths than
strict XY. A deadlock-free escape route does not automatically guarantee
livelock freedom: a non-minimal algorithm still needs a bound or a fairness
argument showing that a packet eventually wins arbitration.

=== Faults and Guaranteed Delivery

A deterministic route that assumes every link and router is healthy fails when
one component is broken. Fault-aware routing first detects or is told about the
fault, removes the unusable output from the candidate set, and then selects a
route around it. The route table, turn restrictions, and deadlock proof must be
updated consistently; otherwise a local workaround can create a global cycle.

Useful fault-tolerance goals are:

- *Connectivity*: every healthy source-destination pair still has a route.
- *No silent loss*: corrupted or dropped packets are detected and retried or
  reported to the protocol.
- *Guaranteed delivery*: under the stated fault model and finite injection,
  each accepted packet eventually reaches its destination.
- *Graceful degradation*: traffic is redistributed without requiring a global
  redesign for every single-link fault.

Adaptive routing is well suited to bypassing faults, but it should separate
fault avoidance from congestion avoidance. A route that is safe under normal
traffic may become unsafe when a failed link changes the dependency graph.

== Flow Control and Buffered Transport

Flow control answers *when* a packet or flit may consume a downstream buffer or
link. It prevents an upstream sender from overwriting data that the receiver
cannot accept. The granularity of allocation determines the buffering and
latency behavior.

=== Store-and-Forward

In *store-and-forward* flow control, a router receives and stores the entire
packet before requesting the next link. The packet is the flow-control unit.
This is simple and can release the input link quickly, but every hop needs room
for a complete packet and adds a packet-sized serialization delay. For a packet
of $L$ bits and link bandwidth $b$, the same payload may be copied through many
queues before its tail moves.

=== Virtual Cut-Through

*Virtual cut-through* starts forwarding after the header arrives and the next
output has been allocated. It lowers latency because the head can cross several
routers while the tail is still entering the first router. However, the router
must reserve enough storage for the *whole* packet in case the downstream link
blocks. Under contention, the packet is absorbed into that one router and the
scheme degenerates toward store-and-forward.

=== Wormhole Flow Control

In *wormhole* flow control, a packet is split into flits. The header flit carries
the destination and route state; body and tail flits follow the header through
the reserved sequence of channels. A blocked header stops the worm, leaving
parts of the packet distributed across links and small input buffers. This
greatly reduces storage and makes long-packet latency close to a pipelined
header latency plus serialization, but it exposes channel dependencies and
head-of-line blocking.

#three-line-table(
  columns: (1.35fr, 1.55fr, 1.65fr, 2.1fr),
  inset: 5pt,
  align: left,
)[
  | *Mode* | *Flow unit* | *Storage needed* | *Main behavior* |
  | :---- | :--------- | :--------------- | :------------- |
  | Store-and-forward | Whole packet | One packet per occupied router | Simple; high hop-by-hop latency |
  | Virtual cut-through | Packet reservation, header-triggered forwarding | Whole packet if blocked | Low latency when links stay free; can degenerate under contention |
  | Wormhole | Flit | A few flits per VC/input | Pipelined and storage-efficient; HOL and dependency hazards |
]

=== Head-of-Line (HOL) Blocking

An input FIFO can contain a red packet at its head that wants a busy output and
a blue packet behind it that wants a free output. FIFO service prevents blue
from leaving, so the free output sits idle. This is *head-of-line (HOL)
blocking*. It lowers throughput even though the network has spare capacity.

=== Virtual Channels

*Virtual channel flow control* divides an input buffer into several logical
queues that share one physical link. Each packet carries a VC identifier; the
router tracks the downstream VC and arbitrates among eligible VCs. In the HOL
example, the blue packet can use its own VC and reach a free output while red
waits.

VCs also provide architectural isolation:

- Assign different traffic classes (requests, replies, I/O, or real-time
  flows) to separate queues and priorities.
- Enforce an ordered VC progression or reserve an escape VC to break deadlock.
- Keep protocol classes such as address and data traffic from forming a cycle
  through one another.

More VCs reduce HOL and can raise throughput, but each VC needs buffer entries,
state, allocation decisions, and credit signals. At some point the area and
energy cost of the queues outweighs the throughput gain.

=== Communicating Buffer Availability

Three common schemes communicate whether a downstream resource can accept
traffic:

#three-line-table(
  columns: (1.35fr, 2.25fr, 2.25fr),
  inset: 5pt,
  align: left,
)[
  | *Scheme* | *Protocol* | *Tradeoff* |
  | :------ | :--------- | :-------- |
  | Credit-based | The downstream router returns one credit whenever a buffer slot is freed; the upstream sender counts available slots | Precise utilization, but return latency and signaling matter, especially for one-flit buffers |
  | XON/XOFF (on/off) | The downstream asserts XOFF near a fullness threshold and XON after draining below a safe threshold | Very little state and wiring; threshold margin must cover in-flight flits and hysteresis |
  | ACK/NACK | The sender transmits optimistically and keeps data until an acknowledgement or negative acknowledgement arrives | Avoids explicit credits, but retained copies waste storage and retransmission can be expensive |
]

For credit flow control, let $T_"rt"$ be the round-trip time from a slot being
freed to the sender receiving its credit, and let one flit take $T_"f"$ to
transmit. A link can stay busy during the feedback gap only if the downstream
buffer has enough entries to cover roughly

$ B_"min" >= ceil(T_"rt" / T_"f") $

in-flight flits (plus implementation margin). Too few entries cause bubbles:
the upstream waits for a credit even though the downstream has just freed a
slot. XON/XOFF uses the same principle through a *Foff* threshold: XOFF must
arrive before outstanding flits can overflow the buffer, while XON must arrive
early enough that the sender does not run dry.

== Router Microarchitecture

A conventional input-buffered wormhole router is a small pipeline around a
crossbar. A five-port 2-D mesh router has north, east, south, west, and local
ports; each input can contain several VC queues.

#figure(
  table(
    columns: (1.45fr, 1.65fr, 2.35fr),
    inset: 6pt,
    align: center + horizon,
    stroke: 0.45pt,
    [*Stage*], [*State / unit*], [*Purpose*],
    [Input buffering], [VC FIFO + credit state], [Accept flits only when a downstream slot is available; preserve packet order within a VC],
    [Route computation (RC)], [Destination, source, or table lookup], [Produce one or more legal output ports and a VC class],
    [VC allocation (VA)], [Input VC -> downstream VC], [Reserve a free downstream VC for a packet or header],
    [Switch allocation (SA)], [Input/VC -> output], [Arbitrate which eligible flit crosses each output this cycle],
    [Crossbar traversal], [Radix-by-radix switch], [Move the selected flit from an input to an output],
    [Link traversal / ejection], [Output register and local NI], [Drive the neighbor or deliver the packet to the endpoint],
  ),
  caption: [A typical router datapath. Route, VC, and switch allocation may be pipelined or speculated, but each decision must respect flow-control state.],
)

The router's *radix* determines crossbar size and allocator complexity. A
five-by-five crossbar is common for an ordinary 2-D mesh router with north,
east, south, west, and one local port. A concentrated mesh attaches multiple
local terminals to each router and therefore usually has a higher radix.
Look-ahead route computation can calculate the next router's output while the
current flit is crossing, reducing latency at the cost of extra metadata and
verification.

An input-buffered design is not the only choice. Output-buffered routers move
arbitration toward the destination but need an internal transfer fabric;
centralized buffers simplify sharing but require high-bandwidth write/read
ports. Bufferless deflection routers remove most queues and use a different
allocator, discussed below.

== Interconnect Performance

Performance must be measured at both the network and application levels. A
short packet latency is useful only if it improves cache-miss completion and
does not starve another traffic class.

=== Latency Equations

Let $d_"wire"$ be the physical Manhattan length of the wires between a source
and destination, not the number of router hops. A packet of $L$ bits on a
channel of bandwidth $b$ with signal propagation velocity $v$ has an ideal
lower bound:

$ T_"ideal" = d_"wire" / v + L / b $

Real networks segment long wires and insert routers. With $H$ traversed
routers, per-router delay $T_"router"$, and contention delay $T_"c"$:

$ T_"actual" = d_"wire" / v + L / b + H dot T_"router" + T_"c" $

The first two terms are physical propagation and serialization. The router term
includes buffering, route/VC/switch allocation, and pipeline registers. The
contention term includes waiting for credits, arbitration, blocked packets,
retries, and detours. A non-minimal route increases both $d_"wire"$ and
potentially $H$; larger packets increase serialization and queue occupancy.

For a stream of packets, useful metrics are:

#three-line-table(
  columns: (1.5fr, 2fr, 2.2fr),
  inset: 5pt,
  align: left,
)[
  | *Metric* | *Definition* | *Interpretation* |
  | :------ | :----------- | :--------------- |
  | Zero-load latency | Latency with no competing traffic | Exposes topology, route, flow-control, and router pipeline cost |
  | Average / tail packet latency | Mean or percentile from injection to ejection | Captures queueing and fairness; tail latency often matters to QoS |
  | Round-trip latency | Request plus response completion time | Directly reflects many cache and synchronization operations |
  | Injection rate | Offered packets or flits per cycle per endpoint | Independent variable for a load-latency experiment |
  | Saturation throughput | Injection rate at which latency begins to grow without bound or reaches a knee | Capacity under a traffic pattern, route, and flow-control policy |
  | Application execution time / job throughput | End-to-end completion or jobs per unit time | Includes core stalls, MLP, synchronization, and interference |
]

At low injection rate, latency is near the zero-load floor. As load rises,
queues increase and the curve bends upward. The saturation point is not a
single topology constant: routing can leave some links underused, flow control
can create bubbles, and the traffic pattern can overload a particular cut.

=== Throughput and Queueing Intuition

If a resource receives average arrival rate $A$ and has service rate
$S$, utilization is $U = A / S$. As $U$ approaches one, queueing
delay grows sharply; a small burst or detour can push the resource into
saturation. Little's law gives a useful consistency check:

$ Q = A dot W $

where $Q$ is average in-flight packets/flits, $A$ is completed traffic per
cycle, and $W$ is average time in the network. Increasing buffers can raise
throughput by keeping links busy, but it also allows more packets to wait and
can increase latency and energy.

== On-Chip Networks (NoCs)

An on-chip network connects cores, private or shared cache banks, memory
controllers, accelerators, and I/O logic on one die. A common baseline is a
packet-switched 2-D mesh with XY routing, FIFO or round-robin arbitration, and
virtual-channel buffers. Most traffic consists of cache misses, coherence
messages, memory requests, and their responses.

The network is often separated into multiple logical fabrics when the traffic
classes have incompatible requirements. A tiled processor can use independent
request, response, I/O, and core-message networks with wormhole packet
switching, plus a circuit-switched streaming network. Separating classes avoids
protocol cycles and lets a streaming flow reserve predictable bandwidth.

=== On-Chip versus Off-Chip Constraints

#three-line-table(
  columns: (1.45fr, 2.15fr, 2.15fr),
  inset: 5pt,
  align: left,
)[
  | *Dimension* | *On chip* | *Off chip* |
  | :--------- | :------- | :--------- |
  | Wiring | Abundant short wires and many metal layers, but 2-D placement and congestion constrain them | Pins, packages, connectors, and cables are scarce and expensive |
  | Distance | Low propagation latency; long RC wires need repeaters roughly every millimeter or two | Longer electrical/optical paths and interface serialization dominate |
  | Main cost | Switches, buffers, crossbars, repeaters, and dynamic/static energy | I/O drivers, pins, SerDes, connectors, and channel power |
  | Workload | Fine-grained cache, coherence, memory, and synchronization traffic | Larger messages between chips, boards, or machines |
  | Design pressure | Keep logic, queues, and control simple enough for timing and power | Use bandwidth efficiently despite few physical channels and higher link latency |
]

The apparent abundance of on-chip wires changes the optimization target. Wide
channels and extra links may be affordable, while large SRAM buffers and
high-radix switches are expensive in area and leakage. On-chip algorithms also
have a tight power budget: a sophisticated global congestion algorithm can cost
more energy than it saves.

=== Why Buffering Is a Tradeoff

Buffers absorb bursts and allow a packet to wait while another packet uses a
link. They increase the set of traffic patterns that can keep links busy and
therefore usually raise saturation throughput. They also:

- consume dynamic energy on every read and write, plus static leakage while
  idle;
- occupy substantial SRAM and control area (input buffers dominated a large
  fraction of some early NoC implementations);
- require VC state, allocation logic, credit return paths, and verification;
- add queueing delay and can hide congestion until buffers are full;
- make deadlock avoidance and QoS bookkeeping more involved.

The useful design point is often a small number of flits per VC rather than the
largest possible queue. A zero-buffer design can be attractive at low offered
load, while a larger buffer wins once burstiness or a hot spot dominates. The
load-latency curve, not a buffer-count slogan, should determine the choice.

== Bufferless Deflection Routing

Bufferless routing removes input queues from intermediate routers. A flit is
kept in a pipeline latch or on a link and must be assigned to some output every
cycle. If no productive output (one that moves it closer to its destination) is
free, the router sends it through a nonproductive output: the flit is
*deflected* or *misrouted*. This is also called hot-potato routing.

The basic BLESS policy is:

1. Rank all incoming flits, commonly oldest first.
2. For the highest-ranked flit, choose an available productive output.
3. For each remaining flit, choose its best free output, using a deflection
   only when all productive choices are occupied.
4. Inject a new flit only when a local input/output slot is free.

Because every accepted flit moves, there is no buffer wait cycle and therefore
no buffer-dependent deadlock. An oldest-first ranking gives a progress argument
against livelock: a packet eventually becomes the oldest and receives a
productive opportunity. BLESS can adapt around a congested area without
maintaining downstream credits or VCs.

#three-line-table(
  columns: (1.55fr, 2.1fr, 2.05fr),
  inset: 5pt,
  align: left,
)[
  | *Benefit* | *Why* | *Cost / limitation* |
  | :------- | :-- | :------------------ |
  | Area and energy reduction | Removes most SRAM queues, credit wires, and VC allocators | Every deflection can traverse extra links and routers |
  | Simple local flow control | A flit is forwarded whenever an output exists | Receiver/ejection buffering and packet metadata still matter |
  | Adaptivity | Congested productive ports can be bypassed immediately | At high load, deflections create more traffic and reduce saturation throughput |
  | Deadlock avoidance | Flits do not wait for a downstream buffer | Livelock and starvation still require a fair ranking |
  | Lower router storage | Pipeline latches hold only current flits | Header/routing information may need to be repeated in every flit |
]

The central result is workload-dependent. In lightly or moderately loaded
networks, bufferless routing can save substantial area and energy with little
execution-time penalty; under sustained hot spots, unnecessary detours can make
it slower than a buffered design. The receiver still needs enough state to
reassemble packets and to handle a flit arriving when its endpoint is busy. In
the BLESS evaluation, removing buffers saved about 32% network energy even in a
dense-network/perfect-cache configuration and about 60% area, with minimal
average slowdown. These are design-point results, not a claim that every load
can run bufferless.

=== CHIPPER: Making Bufferless Routers Practical

BLESS's oldest-first global sort and full permutation allocator can lengthen a
router's critical path; the evaluated implementation was about 43% longer than
the buffered-router critical path. It also leaves two correctness problems:

- *Livelock*: an arbitrary deflection policy can keep one packet wandering.
- *Reassembly deadlock*: if a destination has a finite reassembly buffer, a
  packet can occupy links while waiting for space, blocking other packets that
  would free that space.

CHIPPER (Cheap Interconnect Partially-Permuting Router) addresses these issues
with a short, partially permuting allocator and a *golden packet* priority.
The golden packet is selected by a rotating/static order and is given a
guaranteed productive opportunity; other flits use a simpler local priority.
This avoids a full age-sorting network while preserving livelock freedom.

For reassembly, CHIPPER uses a *retransmit-once* protocol. If a destination
cannot accept a packet, it records the packet identity and asks the source to
retry after space is available rather than allowing a permanently blocked worm
to hold network resources. Cache miss status holding registers (MSHRs) or
miss buffers can double as reassembly storage, making the intermediate network
effectively bufferless without allocating a worst-case packet-sized queue at
every node.

#three-line-table(
  columns: (1.55fr, 2.15fr, 2fr),
  inset: 5pt,
  align: left,
)[
  | *CHIPPER mechanism* | *Problem addressed* | *Remaining concern* |
  | :------------------ | :----------------- | :----------------- |
  | Golden packet / rotating priority | Guarantees forward progress without a long age sort | Priority metadata and a fair rotation are required |
  | Partially permuting switch allocator | Shortens the critical path and simplifies control | Some permutations are not realized in one cycle |
  | Retransmit-once | Prevents a full reassembly buffer from creating a network cycle | Needs packet identity, retry state, and endpoint cooperation |
  | MSHR-backed reassembly | Reuses storage already associated with an outstanding miss | Capacity is tied to endpoint miss-buffer availability |
]

Reported evaluations show that CHIPPER retains much of the bufferless
area/power savings while bringing router timing closer to a conventional
buffered router. The exact percentage depends on technology, flit width,
network size, and workload; the design lesson is the decomposition of
correctness (progress and reassembly) from the choice of queue storage.

=== MinBD: Minimal Buffering for Deflections

MinBD (Minimally-Buffered Deflection Router) keeps the bufferless datapath but
adds a small side buffer that stores only flits that *would otherwise be
deflected*. It does not buffer every flit at every hop. A dual-width ejection
path can accept two flits per cycle when many packets reach the same endpoint,
removing an ejection bottleneck. Two-level prioritization uses a golden packet
for guaranteed progress and a silver/secondary priority to reduce avoidable
deflections.

The side buffer is valuable because a small amount of storage can prevent a
large number of extra traversals. The reported studies found that a four-flit
side buffer reduced deflection rate substantially, and that MinBD improved
high-load performance over an unbuffered design while retaining much lower
power and area than a conventional multi-VC router. The exact results quoted
in the lecture are approximately 31% lower power and 36% lower area than the
buffered reference, with about an 8.1% high-load performance gain over the
bufferless baseline.

#three-line-table(
  columns: (1.45fr, 2.2fr, 2.05fr),
  inset: 5pt,
  align: left,
)[
  | *Design* | *Storage / control* | *Typical behavior* |
  | :------ | :------------------ | :---------------- |
  | Buffered VC router | Several VCs and multiple flits per VC at each input | Strong burst absorption and throughput; high buffer energy/area |
  | BLESS | No intermediate input buffers; oldest-first deflection | Low area and energy; more detours and lower capacity at high load |
  | CHIPPER | Bufferless, golden priority, retransmit-once, endpoint reuse | Practical timing and reassembly without full queues |
  | MinBD | Small side buffer, dual ejection, two-level priority | Fewer deflections and better high-load energy efficiency |
]

Bufferless routing is therefore a point in a continuum, not a binary property:
full queues, a few VCs, a side buffer, or no intermediate storage can all be
reasonable depending on load, endpoint buffering, and QoS requirements.

== Packet Scheduling and Application Behavior

After routing and flow control identify the eligible transfers, a switch
allocator still has to choose one packet for each output. A local arbiter may
choose among input ports, VCs, and applications. Common policies are
round-robin, age (oldest first), fixed VC priority, and combinations of these.

Round-robin is fair over time but ignores packet urgency. Pure age favors a
long-running or high-injection application and can make a bursty workload
monopolize a link. A decision that looks fair at one router can also conflict
with decisions at the next router: a packet prioritized at the first hop may
be delayed by a different local policy downstream.

Application-aware scheduling treats the NoC as a shared system resource rather
than a set of independent queues. It can use an application's network
intensity, sensitivity to latency, service class, or measured progress.

#three-line-table(
  columns: (1.55fr, 2.1fr, 2.1fr),
  inset: 5pt,
  align: left,
)[
  | *Policy* | *Priority signal* | *Strength / weakness* |
  | :------ | :---------------- | :------------------- |
  | Round robin | Rotating input or VC pointer | Simple and broadly fair; ignores urgency and application impact |
  | Age | Time since injection or request creation | Protects old packets; can favor heavy injectors |
  | Fixed class / VC | Configured traffic class | Predictable isolation; can starve lower classes without quotas |
  | Application-aware | Network intensity, sensitivity, or global rank | Better system throughput; requires metadata and coordinated policy |
  | Slack-aware | Estimated cycles that can be hidden by other work | Directly targets packets that can stall execution; prediction can be imperfect |
]

The table uses the same local-arbiter building blocks as a conventional NoC;
the difference is which metadata the arbiter sees and how priorities are
coordinated across routers.

The *STC* example makes the coordination concrete. Packets are grouped
into time batches, applications receive a single ranking that is reused at all
routers, and each router serves contenders in that global order instead of
inventing a conflicting local priority. Older batches and age within a rank
bound starvation. In the small example, average stall time falls from 8.3
cycles with round robin and 7.0 with age to 5.0 with STC. The numbers are
illustrative; the important property is a stable network-wide application rank
combined with an age-based escape from starvation.

=== Memory-Level Parallelism and Packet Slack

*Memory-level parallelism (MLP)* allows a core to overlap several outstanding
cache misses. Consequently, packet latency is not identical to processor stall
time. If one miss is waiting while another miss is already on the critical
path, delaying the first packet may have no visible effect.

Define the *slack* of packet $P$ as the number of cycles by which a router may
delay $P$ without significantly changing application execution time. A useful
approximation is

$ "Slack"(P) = max_(Q in "Pred"(P)) "Latency"(Q) - "Latency"(P) $

where Pred(P) is the set of predecessor cache-miss packets outstanding when
$P$ is issued. A packet with zero or negative estimated slack is critical; a
packet with large positive slack can wait behind it. In practice, latency is
predicted from whether a request is likely to miss in L2 and from Manhattan
hop distance. The prediction need not be exact to distinguish very urgent
packets from packets whose latency is hidden by MLP.

=== Aergia: Slack-Driven Scheduling

Aergia attaches a compact slack priority to each packet at injection and
prioritizes lower-slack packets in the routers. To avoid starvation, time is
partitioned into batches: packets from an older batch outrank packets from a
newer batch, and slack or a local round-robin pointer breaks ties. A compact
implementation can encode:

#three-line-table(
  columns: (1.35fr, 2.1fr, 2.2fr),
  inset: 5pt,
  align: left,
)[
  | *Field* | *Meaning* | *Why it helps* |
  | :----- | :------- | :------------- |
  | Batch | Age epoch of the packet | Bounds starvation and makes priorities stable across routers |
  | Predecessor-L2 bit | Whether any outstanding predecessor is likely an L2 miss | Estimates how much latency can be hidden |
  | This-packet-L2 bit | Whether the packet itself is likely to miss in L2 | Distinguishes long-latency packets |
  | Hop estimate | Difference between predecessor and packet route lengths | Refines the slack estimate with topology |
]

The key principle is to prioritize *criticality*, not simply age. In the
reported workloads, shortest-job-first alone improved weighted speedup by
8.9%, Aergia alone improved throughput by 10.3%, and the combined policy
improved throughput by 16.1% and network fairness by 30.8%. These numbers are
workload and model dependent;
the reusable result is that MLP creates exploitable heterogeneity among packets
from the same and different applications.

== Congestion and Source Throttling

Congestion occurs when offered traffic competes for a link, buffer, ejection
port, or memory endpoint whose service rate is lower than the aggregate demand.
Queueing then increases latency, which can reduce useful instruction progress
and change the future injection pattern. On-chip cores often self-throttle when
they wait for misses, but bursts and many independent cores can still overload a
shared region.

*Source throttling* deliberately delays new packet injection at the endpoint.
Reducing the offered load can lower queueing enough that completed work per
cycle increases. Throttling every node equally is usually wasteful because
applications differ in both network intensity and sensitivity.

=== HAT: Heterogeneous Adaptive Throttling

HAT combines two feedback loops:

1. *Application-aware throttling*: estimate network intensity, for example with
   L1 misses per thousand instructions (L1 MPKI), classify applications into
   network-intensive and network-non-intensive groups, and throttle the
   intensive applications that interfere with latency-sensitive neighbors.
2. *Network-load-aware rate control*: measure a load signal such as link
   occupancy, deflection rate, or outstanding traffic and adjust the
   throttling rate toward the design's peak-performance load.

If measured load is above the target, HAT raises the fraction of cycles in
which injection is blocked; if load is below the target, it relaxes the block.
Classification and rate changes are performed at epoch granularity rather than
every cycle, reducing control overhead and avoiding reactions to individual
packets.

#figure(
  table(
    columns: (1.55fr, 1.85fr, 2.35fr),
    inset: 6pt,
    align: center + horizon,
    stroke: 0.45pt,
    [*Epoch point*], [*Measurement*], [*Action*],
    [Beginning], [L1 MPKI / application intensity], [Classify applications and choose which sources may be throttled],
    [Beginning], [Network load and recent performance], [Set or adjust the target injection/throttling rate],
    [During epoch], [Counters for occupancy, deflections, and injected/completed packets], [Accumulate feedback without changing every individual arbitration decision],
    [Next epoch], [Updated counters and application phase], [Reclassify and retune for the new workload phase],
  ),
  caption: [Epoch-based HAT control. The controller changes source injection, while routers continue to forward packets locally.],
)

HAT is not simply a lower global injection cap. It spends throttling budget on
the sources that create the most interference and adapts when the workload
changes. In the reported buffered-NoC experiment it improved weighted speedup
by about 3.5%; the energy-efficiency graph reports about 8.5% and 5% gains for
the evaluated network variants. Related application-aware congestion-control
work demonstrates that the approach can scale to thousands of cores. The exact
gain depends on traffic pattern, router type, and the chosen load signal.

=== Scheduling and Throttling Together

Scheduling determines *which* ready packet wins; throttling determines *whether
new work enters*. A useful control loop is:

application behavior -> injection -> congestion -> packet priority -> completion

Slack-aware priority can protect a critical packet already in the network,
while HAT can prevent a noncritical, network-intensive source from filling the
network in the first place. Neither mechanism removes the need for deadlock
freedom, reliable packet delivery, or a fair service rule.

== Topology-Aware QoS and MECS

Quality of service may require minimum bandwidth, bounded latency, isolation
between virtual machines, or fairness among cache and memory traffic. Adding
priority queues, counters, and admission control to *every* router provides
strong control but costs area, power, and verification effort. It also
duplicates state in regions where traffic never conflicts.

*Topology-aware QoS* limits the expensive machinery to the places where flows
actually share a resource. Dedicated QoS-enabled routers or channels surround
a shared-resource region (for example, memory controllers); the rest of the
die uses simpler routing and flow control. Routing rules guide each
application into its assigned region without crossing another application's
private paths.

#three-line-table(
  columns: (1.55fr, 2.1fr, 2.1fr),
  inset: 5pt,
  align: left,
)[
  | *QoS concern* | *Topology-aware response* | *Benefit* |
  | :----------- | :------------------------- | :------ |
  | Shared memory/controller bandwidth | Isolate the shared region and apply bandwidth arbitration there | QoS state is concentrated where contention is real |
  | Intra-VM cache traffic | Keep private traffic on local or dedicated paths | Less interference without network-wide priority logic |
  | Inter-VM sharing | Route through controlled gateways and VCs | Explicit admission and service guarantees |
  | Large unconstrained region | Use simpler elastic or bufferless flow control outside QoS regions | Lower area, power, and buffering cost |
]

=== Multi-Drop Express Channels (MECS)

MECS is a topology designed for planar on-chip wiring and low-diameter access.
It provides one-to-many express channels: a source can inject onto a row or
column channel and reach multiple destinations through controlled drop points.
For the idealized organization, a destination is reachable in about two hops
(source to shared channel, then channel to destination), and each row/column
has $k$ channels. The topology is asymmetric: not every node has the same
number or direction of express links.

#figure(
  html.frame(mecs-topology()),
  caption: [Conceptual MECS organization. Express row/column channels provide one-to-many reach, while arbitration controls which packet drops at each node.],
)

#three-line-table(
  columns: (1.45fr, 2.2fr, 2.1fr),
  inset: 5pt,
  align: left,
)[
  | *MECS property* | *Advantage* | *Cost / risk* |
  | :------------- | :-------- | :------------ |
  | One-to-many channels | A single express segment can serve several destinations | Drop-point arbitration and channel sharing are more complex |
  | Low diameter (about two hops) | Short paths to distant nodes and shared resources | A hot shared channel can become a bottleneck |
  | Row/column channel scaling | More channels can use available planar wires efficiently | Asymmetry complicates placement and routing |
  | Rich connectivity | QoS regions can be reached without traversing every router | Requires topology-aware route and admission rules |
]

Kilo-NoC uses the MECS insight to provide strong service guarantees without
putting a full QoS router at every tile. A *topology-aware QoS* (TAQ) design
concentrates VC allocation and priority bookkeeping in shared-resource
regions. A more general preemptive virtual-clock (PVC) scheme can provide QoS
at every node but costs more. Outside the protected regions, elastic-buffer
(EB) or simpler flow control can reduce buffering. The proposed hybrid
organization combines TAQ in shared regions with low-cost flow control
elsewhere.

The design principle is broader than MECS: use connectivity and placement to
isolate traffic first, then spend scheduling and buffering hardware only where
flows can interfere. Low diameter helps latency, but guarantees still require
explicit route restrictions, admission control, and a proof that the chosen
flow-control classes cannot deadlock.

== Putting the Pieces Together

An interconnect design is a coupled set of choices:

#three-line-table(
  columns: (1.45fr, 2.05fr, 2.35fr),
  inset: 5pt,
  align: left,
)[
  | *Question* | *Relevant choice* | *Failure if ignored* |
  | :-------- | :---------------- | :------------------ |
  | Which endpoints communicate? | Topology, concentration, and network partitioning | Unused links in one region and overloaded links in another |
  | Which path is legal? | Deterministic, oblivious, or adaptive routing; minimal or non-minimal detours | Contention, deadlock, livelock, or inability to bypass faults |
  | What waits in a router? | Store-and-forward, virtual cut-through, wormhole, VC depth, side buffer, or deflection | Excess area/energy, HOL blocking, or low saturation throughput |
  | Who wins a conflict? | Round robin, age, application-aware, slack-aware, or QoS arbitration | Starvation, unfair slowdown, or poor end-to-end performance |
  | How is load controlled? | Credits, XON/XOFF, ACK/NACK, source throttling, and epoch feedback | Buffer overflow, bubbles, congestion collapse, or wasted capacity |
  | What does the application need? | Packet format, ordering, reliability, QoS, and endpoint reassembly | Correctness failures hidden by a fast network metric |
]

For a new design, evaluate at least four traffic patterns: uniform random,
nearest-neighbor, hotspot, and the application's measured trace. Report
zero-load and tail latency, saturation throughput, link and buffer energy,
area, fairness, and end-to-end execution time. Then test faults, bursts, and
phase changes. A topology that wins one synthetic curve may lose once routing,
MLP, memory-controller service, and endpoint backpressure are included.

The recurring lesson is to match the mechanism to the bottleneck. A regular
mesh with XY routing favors simple layout and predictable correctness;
adaptive or Valiant routes address correlated load; VCs and escape paths
provide progress under wormhole flow control; BLESS, CHIPPER, and MinBD trade
queues for deflection; Aergia/STC and HAT act on packet criticality and source
injection; and topology-aware QoS with MECS-style shared regions provides
guarantees without placing expensive QoS hardware at every router.

#series-navbar("en", nav)
