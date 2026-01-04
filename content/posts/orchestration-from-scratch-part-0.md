---
date: '2026-01-04T15:58:13+01:00'
draft: false
title: 'Orchestration From Scratch - Part 0'
---

It's rare that I write "useful" software to scratch my own itches these days, but
I find myself wanting a nicer way to deploy "things" to "places" (across my own
hardware and the cloud) - but I don't really want to pay for running Kubernetes
in multiple regions "at home", and want to add non-linux compute options too.

Historically, I'd have solved these problems with Nomad, but I let my personal 
fork languish and I'd like to avoid contributing to a BSL codebase on my
personal time. Even for my favourite project to have ever been a maintainer of.

So... I'm going to write yet another orchestration tool. You probably shouldn't
use it (_I_ might not even use it), but I'm going to walk you through the 
process of building a minimally "useful" orchestrator.

## High level design

```
                                                                    ┌───────────────────┐     
                                                                    │                   │     
                                                                    │   Object Storage  │     
                                                                    │                   │     
                                                                    └───────────────────┘     
                                                                              ▲               
                                   ┌─────────────────────────┐                │               
                                   │                         │                │               
                                   │      Control Plane      │───────Backup───┘               
                                   │                         │                                
                                   └─────────────────────────┘                                
                                                ▲                                             
                                                │                                             
                                                │                                             
           ┌───────────────────────┬────────────┴──────────┬───────────────────────┐          
           │                       │                       │                       │          
           │                       │                       │                       │          
           │                       │                       │                       │          
           │                       │                       │                       │          
┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐
│                    │  │                    │  │ Very Big           │  │                    │
│  Linux agent at    │  │  macOS agent at    │  │ Linux agent in     │  │  Random cloud      │
│  home              │  │  home              │  │ Hetzner            │  │  agents            │
│                    │  │                    │  │                    │  │                    │
└────────────────────┘  └────────────────────┘  └────────────────────┘  └────────────────────┘
```

The control plane will be single-node and [backed by SQLite](https://danielle.fyi/posts/sqlite-is-edge-scale/), as much as there are far more fun and interesting ways to build a scheduling control plane, they can come later - a single node is good enough for me today, and SQLite has very low operational overhead.

The scheduler design will however echo that of Nomad - and is heavily inspired by [Omega](https://storage.googleapis.com/gweb-research2023-media/pubtools/3295.pdf) with a shared-state scheduler with optimistic concurrency (I'll explain this later). Do I need the performance? No. Do I want a playground for different scheduling algorithms? Yes.

Secrets will be supported, and encrypted per-agent in transit, but the control plane will rely on encrypted disks and backups. This is a fine complexity/security tradeoff for personal use.

Service discovery is an unknown for now. My personal software mostly embeds
[tsnet](https://tailscale.com/kb/1244/tsnet), but it would be interesting to
explore making the orchestrator "tailscale-native" now that [Tailscale
Services](https://tailscale.com/kb/1552/tailscale-services) exist.

The agent will support different execution types. Initially it will only support "run this binary from a remote url" and "run this container from an oci registry".

## What's next?

I'll follow up with more posts [as I
build](https://github.com/endocrimes/khonsu). Describing building each piece,
with the decisions that get made along the way. From the job abstraction and the
data model, agent registration and heartbeats, the scheduler, task execution,
and eventually more complex pieces like preemption and failover. I'll try to
keep them focused.

