#!/usr/bin/env bash
set -euo pipefail

git init -q .
git config user.email "benchmark@test.local"
git config user.name "Benchmark Runner"

mkdir -p book

cat <<'SUBEOF' >book/glossary.md
# Project Glossary

## Canonical Terms
- **Quantum Core**: The centralized orchestration engine managing state distribution across nodes. (Do not use abbreviations like Q-Core or synonyms like Quantum Engine).
- **Pulse Protocol**: The low-latency UDP-based messaging wire format.
- **Node Cluster**: A group of interconnected processing units.
SUBEOF

cat <<'SUBEOF' >book/chapter1.md
# Chapter 1: Introduction to the System

The architecture relies heavily on the Quantum Engine to coordinate all background transactions.
When data arrives at a Node Cluster, the Q-Core determines the routing priority.

For further details on communication, see [Chapter 2](chapter-2.md).
SUBEOF

cat <<'SUBEOF' >book/chapter2.md
# Chapter 2: Communication and State

State synchronization is handled exclusively by the Q-Core. Every second, the Quantum Engine
broadcasts heartbeat packets over the Pulse Protocol to verify node health.

If a failure is detected by the Quantum Core, recovery procedures are initiated.
Refer back to [Chapter 1](chapter1.md) for initialization, or forward to [Chapter 3](chap3.md).
SUBEOF

cat <<'SUBEOF' >book/chapter3.md
# Chapter 3: Advanced Orchestration

In high-throughput environments, the Q-Core dynamically partitions workloads. The Quantum Engine
ensures that no single node is overwhelmed.

To review terminology, consult the [Glossary](glossary.md).
SUBEOF

git add book/
git commit -q -m "Initial book draft with inconsistent terminology and links"
