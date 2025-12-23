---
title: "Paxos Overview"
date: 2019-02-09T19:35:55-05:00
lastmod: 2019-02-09T19:35:55-05:00
tags:
  - tech
  - distributed systems
---
_This is a simplified explanation of the Paxos consensus protocol, although it attempts to be mostly correct, there is some nuance lost in the simplification._

Paxos is a consensus protocol proposed by Leslie Lamport in 1989. It is infamous for being hard to understand for most software engineers as the original paper is fairly difficult to read (["Part time parliaments"](https://lamport.azurewebsites.net/pubs/lamport-paxos.pdf)), and many subsequent papers have been written as people try to digest and understand it.

## Replicated State Machines
A replicated state machine works by having multiple [state machines](https://en.wikipedia.org/wiki/Finite-state_machine), also called replicas, working in parallel that maintain the same consistent state.

When a replica receives a request from a client it updates its state by executing the command in the request. It ensures that the state is replicated to the the other replicas in the system so that in the event of a node failure, the state does not get lost.

In a single node system, or where there is only a single client, it is fairly easy to guarantee that the events are replicated in the same order.

In real world systems however, we need to accept requests in parallel. This means that we need multiple nodes to agree on the ordering of requests when applying them to the state machine, to ensure that they all maintain the same state. To do this, they use a _consensus algorithm_ to decide the ordering of commands, and then the state machine applies the commands to do something useful (e.g update a database).

## Terminology

Paxos terminology states that there are three roles in a distributed system that is trying to reach consensus:

- Acceptors (Voters)
- Proposer
- Learner

**Proposer**:

1. Submits a "Prepare" request with a proposal to acceptors, and waits for a majority to reply.
2. If a majority of Acceptors agree, then they will reply with the agreed value. If they disagree, the process starts over.
3. The Proposer then submits an "Accept" request with the proposal number and value to the Acceptors.
4. If the majority of Acceptors accept the commit message, then it is broadcasted to the Learners.

**Acceptor**:

1. Receives a Proposal, and compares it with the highest numbered proposal that it has previously accepted.
2. If the new proposal number is higher, then it is accepted, otherwise it is rejected.
3. Accepts the commit message if its value is the same as a previously accepted proposal and its sequence number is the highest number agreed to.

When a value has been committed, the learners then discover this either through receiving the value from an acceptor directly, or by having a "distinguished Learner" that receives the value from an acceptor and then propagates it to the remaining learners. This guarantees that each command is stored in the same order across replicas.

This process is also known as the _multi-decree Synod_ protocol.

## Practicality
Although Paxos allows you to have complicated topologies across many nodes, with multiple leaders (at the cost of some throughput), and different servers for each of the roles - In most practical applications of Paxos, every _replica_ operates in all three roles, as this simplifies implementation, and makes the overall system easier to reason about.

The following diagram shows a sample flow where replica A receives a request, and runs through a Paxos term with B and C.

```
Client      Replicas
            A  B  C
  #-------->|  |  |  Request
  |         #->|->|  Prepare(ProposalNumber)
  |         |<-#--#  Promise(ProposalNumber, {Va, Vb})
  |         #->|->|  Accept(ProposalNumber, VlastRecived)
  |         #<>#<>#  Accepted(ProposalNumber)
  |<--------#  |  |  Response
  |         |  |  |
```

This version of Paxos, called 'Basic Paxos' allows any node to be a leader for a given request, but can result in a lot of conflicts and low throughput as other nodes may also be trying to Prepare or Commit transactions in parallel.

## Multi Paxos
To increase throughput, 'Multi-Paxos' adds a _stable leader_ to the system, that will be the leader across multiple requests. Follower replicas can forward write requests to the leader node, or redirect them as necessary.

Multi Paxos maintains stable leadership by adding a Round Number to Promises and Commits. The round number must strictly increase monotonically for each step performed by the same leader.

Doing this allows us to remove the Prepare and Promise steps if there has not been a leader election, which decreases latency.  For example, if B were already the leader, a request could be reduced to:

```
Client      Replicas
            A  B  C
  #-------->|  |  |  Request
  |         #->|  |  Forward
  |         |<>#<>|  Accept(ProposalNumber, RoundNumber++)
  |         #<>#<>#  Accepted(ProposalNumber, RoundNumber++)
  |         |<-#  |  Response
  |<--------#  |  |
```


## Summary

I've exhausted my motivation to write a blog post (it's about 45 mins) and this serves the purpose of giving a friend a high level overview, but I'd like to elaborate more on fault tolerance, leader election, and other consensus algorithms in the future.

If you want to read more about consensus now I recommend reading:

- ["Paxos Made Simple" - Leslie Lamport](https://lamport.azurewebsites.net/pubs/paxos-simple.pdf).
- [Byzantine Fault Tolerance](https://en.wikipedia.org/wiki/Byzantine_fault)
- [The Raft Consensus Algorithm](https://raft.github.io/)

