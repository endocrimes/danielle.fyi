---
title: "SQLite is Edge-Scale"
date: 2025-08-29T12:00:00Z
lastmod: 2025-08-29T12:00:00Z
tags:
  - tech
---

Published on the [Fermyon
Blog](https://www.fermyon.com/blog/sqlite-is-edge-scale), a blog post about why
I actually rather like SQLite for distributed systems projects.

<!--

---

A little while ago I mentioned on [Fallthrough](https://fallthrough.transistor.fm/20) that we've been making some pretty heavy use of SQLite as part of our control planes at Fermyon - and some more folks have asked me about it since, so I figured it was worth writing about it.

Over the last few decades, many conventional applications have relied on a layered architecture: a database at the bottom, caches in the middle, and a big Rails/Django/Phoenix/... app on top (plus all the satellite applications, queues, etc. off to the side). That design paradigm works really well when you're running in a single region, especially in the cloud when all the persistent services you want are readily available in a managed form - and for the most part, there's been no serious reason to question this.

When you start thinking about building a distributed control plane, the first things you think about for persistence are probably a mix of etcd/cockroach/foundationdb or some other similarly distributed database. Smaller databases like SQLite have become where people run their tests, or write small hobbyist applications.

However, with the expansion of replicated and edge computing platforms SQLite (or libSQL) actually has an interesting place in the land of large scale distributed computing.

Where? Mostly control planes for me, but the same likely applies to a lot of business applications at scale (see: [expensify](https://use.expensify.com/blog/scaling-sqlite-to-4m-qps-on-a-single-server), not to mention all the places that SQLite lives on consumer devices, cars, and aircraft due to its unparalleled reliability).

## Why not the status quo?

In modern cloud compute it is normal to outsource a lot of core data services to the underlying platform - relying on the provider to manage backups and availability of databases and storage. This is a big part of what makes the cloud so accessible for smaller organizations that can't afford the staff to manage those resources effectively.

With the rise of edge computing, requirements have rapidly shifted, with more compute moving closer to the user in geographically distributed data centers and small points of presence (or, as I’ll call it now, the edge).

Building systems that run at the edge is interesting, because they often operate extensively outside core cloud regions and are likely to face relatively high latency to them. Not to mention contending with public internet flakiness.

This means you need to consider the services you want to require in those platforms quite carefully - especially when your footprint may be constrained by external factors (available rack space/power/cooling being common ones). If you're going to be in many locations, you also need to consider the human cost of running those services - stateful systems need to be carefully managed to handle many modes of failure and security surfaces.

For me, one of the only “we need this, and we need it to work” requirements is object storage, because the object store is one of the most powerful primitives we have in modern computing. It shifts the hard problem of “keep these bits on multiple redundant disks” to a single component, with many semi-compatible storage options offering different levels of functionality, performance, and support (Ceph + Object Gateway, Minio, plus is offered as a managed service in many small local providers as a value add - even when databases are not).

Sadly, not even close to all object stores support conditional writes, otherwise many control-plane-y applications could happily store their config in an object store, without much more than a local cache of the state.

This means we want to look at database-y options that don't depend on managed databases, and can preferably back themselves up to the object store.

## Raft?

The other distributed systems nerds are now all thinking about building a small raft-based control plane and calling it a day - I know - I've been there. Building new distributed systems is my catnip, and I've built many of them throughout the years - they're fun, exciting, and feel great to work on.

In practice however, building stable systems with Raft *is* very difficult to do well, and when they fail, it is often in new and exciting ways that can be very hard to recover from during an active incident, requiring a very small set of experts to triage them. You also still need to store your data on those nodes, and common choices like BoltDB come with a whole slew of problems - namely around debug-ability and developer friendliness - and it can be hard to prioritize building the required tooling before issues arise in production.

There are many cases where consensus and distributed state can be the right answer to your problems, but it's safe to say they shouldn't be your *first* answer to a problem.

### SQLite?!

I ended up coming to the same conclusion as [Ben Johnson](https://github.com/benbjohnson) and started seriously considering SQLite - it's easy to deploy, easy enough to program against (but a little frustrating at first when you're used to the creature comforts of Postgres or MariaDB - the data being local does just let you query and filter in code though), and easy to test.

In exploring those ideas... I went from feeling a little... ridiculous... to almost convinced.

Why?

Performance and scalability quickly became non-issues. A 4 vCPU VPS can handle ~180k reads/second from SQLite without any special optimization, and in 2025 it’s often easier to get access to *bigger* servers than to get *more* of them (e.g Kubernetes' relatively low cluster scaling limits, but also as server CPUs move towards dense configurations with 192 cores in a single socket). For many control plane applications - especially those that can be sharded - you are unlikely to outgrow the hardware you can execute on.

Reliability also wasn’t a serious concern. SQLite’s test suite is ridiculously comprehensive, and it’s (probably?) the most widely installed database in the world, in environments where a human operator can't resolve issues. As long as memory isn't corrupted, and the underlying disk hasn't failed (where an RDBMS isn't immune to failure either), I trust SQLite to write the data correctly to disk more than many other libraries.

My main remaining hesitations were about downtime during deployment, and state recovery when data is lost.

For the latter, thankfully, other people have now solved this problem - [Litestream](https://github.com/benbjohnson/litestream) exists - and LiteFS is better. I've mostly used Litestream and after fairly extensive testing, I've found it reliable enough, that with some system design guardrails - I trust it to fail only in ways that are easy to recover from and built those considerations into the broader system design.

What about downtime?

Edge systems already have to be resilient to the network link being unavailable for unknown periods of time, alongside other localized issues with power/cooling/... - so our system already had to handle being unable to configure an edge, with monitoring and remediation. In the near term, it's acceptable to have slight downtime during deployments, especially as data can generally be preserved between deploys (bypassing Litestream recovery time) - longer term, I'd love to explore LiteFS more, and the [server mode of libSQL](https://github.com/tursodatabase/libsql).

### What about reality?

Many system design ideas can come crashing down when they meet the real world. In this case, though, it’s been incredibly effective. Giving developers familiar tools to work with, combined with primitives that ensure resilience, has worked well - handling whole and partial data center outages with minimal impact and good self-recovery.

### In conclusion

SQLite has become a common tool at Fermyon for solving persistence problems in
distributed control planes - and we're really happy with it.

I can highly recommend at least considering smaller database options when thinking about your systems at scale. You might be pleasantly surprised.

-->
