# Graph Report - we were not alone  (2026-06-21)

## Corpus Check
- 3 files · ~754 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 14 nodes · 11 edges · 4 communities
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a087af8d`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 3|Community 3]]

## God Nodes (most connected - your core abstractions)
1. `We Were Not Alone` - 4 edges
2. `Architecture Overview` - 3 edges
3. `Project Structure` - 1 edges
4. `Getting Started` - 1 edges
5. `Autoloads` - 1 edges
6. `Components` - 1 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (4 total, 0 thin omitted)

### Community 1 - "Community 1"
Cohesion: 0.50
Nodes (3): Getting Started, Project Structure, We Were Not Alone

### Community 3 - "Community 3"
Cohesion: 0.67
Nodes (3): Architecture Overview, Autoloads, Components

## Knowledge Gaps
- **4 isolated node(s):** `Project Structure`, `Getting Started`, `Autoloads`, `Components`
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `We Were Not Alone` connect `Community 1` to `Community 3`?**
  _High betweenness centrality (0.154) - this node is a cross-community bridge._
- **Why does `Architecture Overview` connect `Community 3` to `Community 1`?**
  _High betweenness centrality (0.115) - this node is a cross-community bridge._
- **What connects `Project Structure`, `Getting Started`, `Autoloads` to the rest of the system?**
  _4 weakly-connected nodes found - possible documentation gaps or missing edges._