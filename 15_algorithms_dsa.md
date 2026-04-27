# Module 15 — Algorithms and Data Structures in Python

> **Level:** Advanced | **Estimated Time:** 10 hours | **Prerequisites:** Modules 01–04

---

## Learning Objectives

By the end of this module you will be able to:
- Analyse algorithm complexity using Big O notation
- Implement and use stacks, queues, linked lists, trees, and graphs
- Apply sorting and searching algorithms
- Solve common algorithmic patterns: two-pointers, sliding window, dynamic programming
- Use Python's `heapq`, `bisect`, and `collections.deque` for optimal solutions
- Approach coding interview problems systematically

---

## 15.1 Big O Notation

### Conceptual Foundation

Big O describes how an algorithm's runtime (or space) grows as input size `n` increases. It expresses the **worst-case upper bound**.

| Notation | Name | Example |
|----------|------|---------|
| O(1) | Constant | Dict lookup, list index |
| O(log n) | Logarithmic | Binary search |
| O(n) | Linear | Linear scan |
| O(n log n) | Linearithmic | Merge sort, heap sort |
| O(n²) | Quadratic | Bubble sort, nested loops |
| O(2ⁿ) | Exponential | Naive recursion (Fibonacci) |
| O(n!) | Factorial | Generating all permutations |

```python
# O(1) — constant: doesn't depend on input size
def get_first(lst: list) -> any:
    return lst[0]

# O(n) — linear: one pass through input
def linear_search(lst: list, target) -> int:
    for i, item in enumerate(lst):
        if item == target:
            return i
    return -1

# O(n²) — quadratic: nested loops, each O(n)
def has_duplicate_slow(lst: list) -> bool:
    for i in range(len(lst)):
        for j in range(i + 1, len(lst)):
            if lst[i] == lst[j]:
                return True
    return False

# O(n) — same problem, better algorithm
def has_duplicate_fast(lst: list) -> bool:
    return len(lst) != len(set(lst))

# Space complexity: O(1) vs O(n)
def sum_range(n: int) -> int:
    return n * (n + 1) // 2    # O(1) space, O(1) time

def sum_range_bad(n: int) -> int:
    return sum(range(n + 1))   # O(n) space (creates range object)
```

---

## 15.2 Core Data Structures

### Stack — LIFO

```python
from collections import deque

class Stack:
    """LIFO stack backed by deque for O(1) push/pop."""

    def __init__(self) -> None:
        self._data: deque = deque()

    def push(self, item) -> None:        # O(1)
        self._data.append(item)

    def pop(self):                        # O(1)
        if self.is_empty():
            raise IndexError("Stack is empty")
        return self._data.pop()

    def peek(self):                       # O(1)
        if self.is_empty():
            raise IndexError("Stack is empty")
        return self._data[-1]

    def is_empty(self) -> bool:           # O(1)
        return not self._data

    def __len__(self) -> int:
        return len(self._data)


# Application: check balanced parentheses
def is_balanced(s: str) -> bool:
    """
    Return True if all brackets in s are properly nested and closed.
    Time: O(n) | Space: O(n)
    """
    pairs = {')': '(', ']': '[', '}': '{'}
    stack = Stack()

    for char in s:
        if char in '([{':
            stack.push(char)
        elif char in ')]}':
            if stack.is_empty() or stack.pop() != pairs[char]:
                return False

    return stack.is_empty()

print(is_balanced("({[]})"))   # True
print(is_balanced("([)]"))     # False
print(is_balanced("{[}"))      # False
```

### Queue — FIFO

```python
from collections import deque

class Queue:
    """FIFO queue backed by deque for O(1) enqueue/dequeue."""

    def __init__(self) -> None:
        self._data: deque = deque()

    def enqueue(self, item) -> None:     # O(1)
        self._data.append(item)

    def dequeue(self):                    # O(1) — use deque, not list.pop(0)!
        if self.is_empty():
            raise IndexError("Queue is empty")
        return self._data.popleft()

    def peek(self):                       # O(1)
        if self.is_empty():
            raise IndexError("Queue is empty")
        return self._data[0]

    def is_empty(self) -> bool:
        return not self._data

    def __len__(self) -> int:
        return len(self._data)


# Application: BFS (Breadth-First Search)
def bfs(graph: dict[str, list[str]], start: str) -> list[str]:
    """
    Breadth-first traversal of a graph.
    Visits nodes level by level — finds shortest path in unweighted graphs.
    Time: O(V + E) | Space: O(V)
    """
    visited = set()
    order = []
    queue = Queue()
    queue.enqueue(start)
    visited.add(start)

    while not queue.is_empty():
        node = queue.dequeue()
        order.append(node)
        for neighbour in graph.get(node, []):
            if neighbour not in visited:
                visited.add(neighbour)
                queue.enqueue(neighbour)

    return order

graph = {
    "A": ["B", "C"],
    "B": ["D", "E"],
    "C": ["F"],
    "D": [], "E": [], "F": [],
}
print(bfs(graph, "A"))   # ['A', 'B', 'C', 'D', 'E', 'F']
```

### Binary Tree

```python
from __future__ import annotations
from typing import Optional, Iterator

class TreeNode:
    def __init__(self, val: int) -> None:
        self.val = val
        self.left: Optional[TreeNode] = None
        self.right: Optional[TreeNode] = None


class BinarySearchTree:
    """
    BST property: all nodes in left subtree < root < all nodes in right subtree.
    Search/Insert/Delete: O(log n) average, O(n) worst (unbalanced).
    """

    def __init__(self) -> None:
        self.root: Optional[TreeNode] = None

    def insert(self, val: int) -> None:           # O(log n) avg
        self.root = self._insert(self.root, val)

    def _insert(self, node: Optional[TreeNode], val: int) -> TreeNode:
        if not node:
            return TreeNode(val)
        if val < node.val:
            node.left = self._insert(node.left, val)
        elif val > node.val:
            node.right = self._insert(node.right, val)
        return node

    def search(self, val: int) -> bool:           # O(log n) avg
        return self._search(self.root, val)

    def _search(self, node: Optional[TreeNode], val: int) -> bool:
        if not node:
            return False
        if val == node.val:
            return True
        return self._search(node.left if val < node.val else node.right, val)

    def inorder(self) -> list[int]:              # O(n) — returns sorted list!
        result = []
        def _inorder(node: Optional[TreeNode]) -> None:
            if node:
                _inorder(node.left)
                result.append(node.val)
                _inorder(node.right)
        _inorder(self.root)
        return result

    def height(self, node: Optional[TreeNode] = None) -> int:  # O(n)
        if node is None:
            node = self.root
        if not node:
            return 0
        return 1 + max(self.height(node.left), self.height(node.right))


bst = BinarySearchTree()
for v in [5, 3, 7, 1, 4, 6, 8]:
    bst.insert(v)

print(bst.inorder())    # [1, 3, 4, 5, 6, 7, 8] — sorted!
print(bst.search(4))    # True
print(bst.height())     # 3
```

---

## 15.3 Sorting Algorithms

```python
# Bubble Sort — O(n²) time, O(1) space
def bubble_sort(arr: list[int]) -> list[int]:
    """Sort in-place using bubble sort (for teaching only — use sorted() in practice)."""
    arr = arr.copy()
    n = len(arr)
    for i in range(n):
        swapped = False
        for j in range(n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
                swapped = True
        if not swapped:
            break   # already sorted — O(n) best case
    return arr

# Merge Sort — O(n log n) time, O(n) space
def merge_sort(arr: list[int]) -> list[int]:
    """Divide and conquer sort — stable, consistent O(n log n)."""
    if len(arr) <= 1:
        return arr
    mid = len(arr) // 2
    left = merge_sort(arr[:mid])
    right = merge_sort(arr[mid:])
    return _merge(left, right)

def _merge(left: list[int], right: list[int]) -> list[int]:
    result, i, j = [], 0, 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            result.append(left[i]); i += 1
        else:
            result.append(right[j]); j += 1
    return result + left[i:] + right[j:]

# Quick Sort — O(n log n) average, O(n²) worst
def quick_sort(arr: list[int]) -> list[int]:
    """In-place quick sort with random pivot."""
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left  = [x for x in arr if x < pivot]
    mid   = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quick_sort(left) + mid + quick_sort(right)

# Python's built-in sort — Timsort, O(n log n), stable
data = [3, 1, 4, 1, 5, 9, 2, 6, 5]
sorted_data = sorted(data)                          # new list
data.sort()                                          # in-place
sorted_people = sorted(people, key=lambda p: p["age"])  # custom key
```

---

## 15.4 Searching Algorithms

```python
import bisect

# Linear Search — O(n)
def linear_search(arr: list, target) -> int:
    for i, val in enumerate(arr):
        if val == target:
            return i
    return -1

# Binary Search — O(log n) — REQUIRES sorted array
def binary_search(arr: list[int], target: int) -> int:
    """Return index of target in sorted arr, or -1 if not found."""
    lo, hi = 0, len(arr) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1

# Use Python's bisect module for sorted insertions
sorted_arr = [1, 3, 5, 7, 9, 11]
pos = bisect.bisect_left(sorted_arr, 7)    # 3 — leftmost position for 7
pos = bisect.bisect_right(sorted_arr, 7)   # 4 — rightmost position

# Insert while keeping sorted order: O(n) due to list shift, but O(log n) search
bisect.insort(sorted_arr, 6)   # [1, 3, 5, 6, 7, 9, 11]

# Find closest value in sorted array
def find_closest(arr: list[int], target: int) -> int:
    pos = bisect.bisect_left(arr, target)
    candidates = []
    if pos < len(arr):
        candidates.append(arr[pos])
    if pos > 0:
        candidates.append(arr[pos - 1])
    return min(candidates, key=lambda x: abs(x - target))
```

---

## 15.5 Common Algorithmic Patterns

### Two Pointers

```python
def two_sum_sorted(arr: list[int], target: int) -> tuple[int, int] | None:
    """
    Find indices of two numbers in SORTED arr that sum to target.
    Time: O(n) | Space: O(1) — no extra data structure needed.
    """
    lo, hi = 0, len(arr) - 1
    while lo < hi:
        current = arr[lo] + arr[hi]
        if current == target:
            return (lo, hi)
        elif current < target:
            lo += 1    # need larger sum
        else:
            hi -= 1    # need smaller sum
    return None

def reverse_string(s: str) -> str:
    """Reverse using two pointers — O(n) time, O(n) space."""
    chars = list(s)
    lo, hi = 0, len(chars) - 1
    while lo < hi:
        chars[lo], chars[hi] = chars[hi], chars[lo]
        lo += 1
        hi -= 1
    return "".join(chars)

def remove_duplicates_sorted(arr: list[int]) -> int:
    """Remove duplicates from sorted array in-place. Return new length."""
    if not arr:
        return 0
    write = 1    # write pointer
    for read in range(1, len(arr)):
        if arr[read] != arr[read - 1]:
            arr[write] = arr[read]
            write += 1
    return write
```

### Sliding Window

```python
def max_sum_subarray(arr: list[int], k: int) -> int:
    """
    Find maximum sum of any subarray of length k.
    Sliding window: O(n) — move window one step at a time.
    """
    if len(arr) < k:
        raise ValueError(f"Array length {len(arr)} < window size {k}")

    window_sum = sum(arr[:k])
    max_sum = window_sum

    for i in range(k, len(arr)):
        window_sum += arr[i] - arr[i - k]   # slide: add new, remove old
        max_sum = max(max_sum, window_sum)

    return max_sum

def longest_unique_substring(s: str) -> int:
    """
    Find length of longest substring without repeating characters.
    Sliding window with a set: O(n) time, O(min(n, alphabet)) space.
    """
    char_set: set[str] = set()
    lo = 0
    max_len = 0

    for hi in range(len(s)):
        while s[hi] in char_set:
            char_set.remove(s[lo])
            lo += 1
        char_set.add(s[hi])
        max_len = max(max_len, hi - lo + 1)

    return max_len

print(longest_unique_substring("abcabcbb"))   # 3 ("abc")
print(longest_unique_substring("pwwkew"))     # 3 ("wke")
```

### Dynamic Programming

```python
def fibonacci_dp(n: int) -> int:
    """
    Fibonacci with bottom-up DP (tabulation).
    Time: O(n) | Space: O(1) — only track last two values.
    """
    if n < 2:
        return n
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b

def coin_change(coins: list[int], amount: int) -> int:
    """
    Minimum number of coins to make up amount.
    Classic DP: O(amount × len(coins)) time, O(amount) space.
    """
    dp = [float("inf")] * (amount + 1)
    dp[0] = 0   # base case: 0 coins needed for amount 0

    for amt in range(1, amount + 1):
        for coin in coins:
            if coin <= amt:
                dp[amt] = min(dp[amt], dp[amt - coin] + 1)

    return dp[amount] if dp[amount] != float("inf") else -1

print(coin_change([1, 5, 10, 25], 36))   # 3 (25+10+1)
print(coin_change([2], 3))               # -1 (impossible)

def longest_common_subsequence(s1: str, s2: str) -> int:
    """
    Find length of longest common subsequence (LCS).
    Time: O(m×n) | Space: O(m×n)
    """
    m, n = len(s1), len(s2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]

    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if s1[i - 1] == s2[j - 1]:
                dp[i][j] = dp[i - 1][j - 1] + 1
            else:
                dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])

    return dp[m][n]

print(longest_common_subsequence("abcde", "ace"))   # 3 ("ace")
```

### Backtracking

```python
def permutations(nums: list[int]) -> list[list[int]]:
    """Generate all permutations of nums using backtracking."""
    result = []

    def backtrack(current: list[int], remaining: list[int]) -> None:
        if not remaining:
            result.append(current[:])
            return
        for i in range(len(remaining)):
            current.append(remaining[i])
            backtrack(current, remaining[:i] + remaining[i+1:])
            current.pop()   # undo choice (backtrack)

    backtrack([], nums)
    return result

print(permutations([1, 2, 3]))
# [[1,2,3], [1,3,2], [2,1,3], [2,3,1], [3,1,2], [3,2,1]]

def subsets(nums: list[int]) -> list[list[int]]:
    """Generate the power set of nums."""
    result = []

    def backtrack(start: int, current: list[int]) -> None:
        result.append(current[:])
        for i in range(start, len(nums)):
            current.append(nums[i])
            backtrack(i + 1, current)
            current.pop()

    backtrack(0, [])
    return result
```

---

## 15.6 Heap and Priority Queue

```python
import heapq

# Python's heapq is a MIN-HEAP
nums = [3, 1, 4, 1, 5, 9, 2, 6]
heapq.heapify(nums)         # convert list to heap in-place: O(n)
smallest = heapq.heappop(nums)   # remove and return smallest: O(log n)
heapq.heappush(nums, 7)          # add element: O(log n)

# n smallest / largest
data = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3]
print(heapq.nsmallest(3, data))  # [1, 1, 2]
print(heapq.nlargest(3, data))   # [9, 6, 5]

# Max-heap trick: negate values
max_heap = [-n for n in data]
heapq.heapify(max_heap)
largest = -heapq.heappop(max_heap)   # get max

# Priority queue with (priority, item) tuples
from heapq import heappush, heappop

pq: list[tuple[int, str]] = []
heappush(pq, (3, "low priority"))
heappush(pq, (1, "high priority"))
heappush(pq, (2, "medium priority"))

while pq:
    priority, task = heappop(pq)
    print(f"[{priority}] {task}")
# [1] high priority
# [2] medium priority
# [3] low priority

# Application: K Largest Elements — O(n log k)
def k_largest(nums: list[int], k: int) -> list[int]:
    """Return k largest elements using a min-heap of size k."""
    heap = nums[:k]
    heapq.heapify(heap)
    for num in nums[k:]:
        if num > heap[0]:
            heapq.heapreplace(heap, num)
    return sorted(heap, reverse=True)
```

---

## 15.7 Graph Algorithms

```python
from collections import defaultdict, deque
from typing import Optional

class Graph:
    """Directed/undirected weighted graph using adjacency list."""

    def __init__(self, directed: bool = False) -> None:
        self._adj: dict[str, list[tuple[str, float]]] = defaultdict(list)
        self._directed = directed

    def add_edge(self, u: str, v: str, weight: float = 1.0) -> None:
        self._adj[u].append((v, weight))
        if not self._directed:
            self._adj[v].append((u, weight))

    def bfs(self, start: str) -> list[str]:
        """Breadth-first search — shortest path in unweighted graph."""
        visited, order = {start}, [start]
        queue = deque([start])
        while queue:
            node = queue.popleft()
            for neighbour, _ in self._adj[node]:
                if neighbour not in visited:
                    visited.add(neighbour)
                    order.append(neighbour)
                    queue.append(neighbour)
        return order

    def dfs(self, start: str) -> list[str]:
        """Depth-first search — explore as deep as possible first."""
        visited, order = set(), []
        def _dfs(node: str) -> None:
            visited.add(node)
            order.append(node)
            for neighbour, _ in self._adj[node]:
                if neighbour not in visited:
                    _dfs(neighbour)
        _dfs(start)
        return order

    def dijkstra(self, start: str) -> dict[str, float]:
        """
        Shortest paths from start to all reachable nodes.
        Time: O((V + E) log V) with a heap.
        """
        dist = defaultdict(lambda: float("inf"))
        dist[start] = 0.0
        heap = [(0.0, start)]

        while heap:
            d, node = heapq.heappop(heap)
            if d > dist[node]:
                continue   # stale entry
            for neighbour, weight in self._adj[node]:
                new_dist = d + weight
                if new_dist < dist[neighbour]:
                    dist[neighbour] = new_dist
                    heapq.heappush(heap, (new_dist, neighbour))

        return dict(dist)

    def has_cycle(self) -> bool:
        """Detect cycle in directed graph using DFS coloring."""
        WHITE, GRAY, BLACK = 0, 1, 2
        color = defaultdict(int)

        def dfs(node: str) -> bool:
            color[node] = GRAY
            for neighbour, _ in self._adj[node]:
                if color[neighbour] == GRAY:
                    return True   # back edge → cycle
                if color[neighbour] == WHITE and dfs(neighbour):
                    return True
            color[node] = BLACK
            return False

        return any(dfs(n) for n in self._adj if color[n] == WHITE)


# Demo
g = Graph(directed=False)
for u, v, w in [("A","B",4), ("A","C",2), ("B","D",5), ("C","D",1), ("D","E",3)]:
    g.add_edge(u, v, w)

print(g.bfs("A"))                 # ['A', 'B', 'C', 'D', 'E']
print(g.dijkstra("A"))            # {'A':0, 'C':2, 'B':4, 'D':3, 'E':6}
```

---

## 15.8 Problem-Solving Framework

Use this systematic approach in interviews and real problems:

```
1. UNDERSTAND — restate the problem; clarify constraints; ask about edge cases
2. EXAMPLES — work through small examples by hand
3. BRUTE FORCE — describe the naive O(n²)/O(2ⁿ) solution
4. OPTIMIZE — what is the bottleneck? Can we use a hash map? Sorting? DP?
5. CODE — write clean, readable code
6. TEST — check edge cases: empty input, single element, duplicates, negatives
```

```python
# Example: "Find the most frequent element in an array"

# STEP 1: Understand
# Input: list of ints (may have negatives, duplicates)
# Output: the element that appears most often (any on tie)

# STEP 2: Examples
# [1,2,2,3,3,3] → 3
# [1] → 1
# [] → raise ValueError

# STEP 3: Brute force — O(n²)
# For each element, count its occurrences. Track max.

# STEP 4: Optimize — O(n) with Counter/hash map

from collections import Counter

def most_frequent(nums: list[int]) -> int:
    """Return the most frequent element in nums. O(n) time and space."""
    if not nums:
        raise ValueError("Input list cannot be empty")
    return Counter(nums).most_common(1)[0][0]

# STEP 6: Test
assert most_frequent([1, 2, 2, 3, 3, 3]) == 3
assert most_frequent([1]) == 1
assert most_frequent([-1, -1, 2]) == -1
try:
    most_frequent([])
except ValueError:
    pass   # expected
```

---

## Best Practices

1. **Always analyse time and space complexity** before coding.
2. **Use built-in data structures** (`heapq`, `deque`, `Counter`) — they are implemented in C.
3. **Consider edge cases first** — empty input, single element, all same, all distinct.
4. **Python's `sorted()` is Timsort** — O(n log n) stable sort; prefer it over custom sorts.
5. **Hash maps solve many O(n²) problems in O(n)** — always ask "can I trade space for time?".
6. **Recursion + memoization = top-down DP**. Loop + table = bottom-up DP.
7. **`bisect` for O(log n) operations on sorted lists** — avoid re-sorting after each insert.

---

## Exercises

### Exercise 15.1 — Valid Parentheses (Easy)
Given a string with `(`, `)`, `{`, `}`, `[`, `]`, return `True` if it is valid.

**Solution:** See `is_balanced()` in section 15.2.

---

### Exercise 15.2 — Merge Intervals (Medium)
Given a list of intervals `[[1,3],[2,6],[8,10],[15,18]]`, merge overlapping ones.

**Solution:**
```python
def merge_intervals(intervals: list[list[int]]) -> list[list[int]]:
    """Merge overlapping intervals. Time: O(n log n) | Space: O(n)."""
    if not intervals:
        return []
    intervals.sort(key=lambda x: x[0])
    merged = [intervals[0]]

    for start, end in intervals[1:]:
        if start <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], end)   # extend
        else:
            merged.append([start, end])               # no overlap

    return merged

print(merge_intervals([[1,3],[2,6],[8,10],[15,18]]))
# [[1,6],[8,10],[15,18]]
```

---

### Exercise 15.3 — LRU Cache (Hard)
Implement an LRU (Least Recently Used) cache with O(1) get and put operations.

**Solution:**
```python
from collections import OrderedDict

class LRUCache:
    """
    LRU Cache using OrderedDict.
    OrderedDict remembers insertion order + supports move_to_end().
    Time: O(1) for both get and put.
    """

    def __init__(self, capacity: int) -> None:
        self.capacity = capacity
        self._cache: OrderedDict[int, int] = OrderedDict()

    def get(self, key: int) -> int:
        if key not in self._cache:
            return -1
        self._cache.move_to_end(key)   # mark as most recently used
        return self._cache[key]

    def put(self, key: int, value: int) -> None:
        if key in self._cache:
            self._cache.move_to_end(key)
        self._cache[key] = value
        if len(self._cache) > self.capacity:
            self._cache.popitem(last=False)  # evict LRU (first item)

cache = LRUCache(2)
cache.put(1, 1)
cache.put(2, 2)
print(cache.get(1))   # 1 (now most recently used)
cache.put(3, 3)       # evict key 2 (least recently used)
print(cache.get(2))   # -1 (evicted)
print(cache.get(3))   # 3
```

---

### Exercise 15.4 — Word Search (Hard)
Given a 2D board and a word, return `True` if the word exists in the grid (can go up, down, left, right; cannot reuse cells).

**Solution:**
```python
def word_search(board: list[list[str]], word: str) -> bool:
    """
    DFS backtracking to find word in 2D grid.
    Time: O(M × N × 4^L) where L = word length.
    """
    rows, cols = len(board), len(board[0])

    def dfs(r: int, c: int, idx: int) -> bool:
        if idx == len(word):
            return True
        if r < 0 or r >= rows or c < 0 or c >= cols:
            return False
        if board[r][c] != word[idx]:
            return False

        temp, board[r][c] = board[r][c], "#"  # mark visited
        found = (
            dfs(r+1, c, idx+1) or dfs(r-1, c, idx+1) or
            dfs(r, c+1, idx+1) or dfs(r, c-1, idx+1)
        )
        board[r][c] = temp  # restore (backtrack)
        return found

    return any(dfs(r, c, 0) for r in range(rows) for c in range(cols))

board = [["A","B","C","E"], ["S","F","C","S"], ["A","D","E","E"]]
print(word_search(board, "ABCCED"))  # True
print(word_search(board, "SEE"))     # True
print(word_search(board, "ABCB"))    # False
```

---

## Module Summary

| Algorithm | Time | Space | Use Case |
|-----------|------|-------|---------|
| Linear search | O(n) | O(1) | Unsorted data |
| Binary search | O(log n) | O(1) | Sorted data |
| Bubble sort | O(n²) | O(1) | Teaching only |
| Merge sort | O(n log n) | O(n) | Stable sort |
| Quick sort | O(n log n) avg | O(log n) | In-place sort |
| BFS | O(V+E) | O(V) | Shortest path (unweighted) |
| DFS | O(V+E) | O(V) | Cycle detection, paths |
| Dijkstra | O((V+E)log V) | O(V) | Shortest path (weighted) |
| DP (coin change) | O(n×k) | O(n) | Optimization subproblems |

---

## Quiz

1. What is the time complexity of binary search and why?
2. Why is `x in my_set` O(1) but `x in my_list` O(n)?
3. What is the difference between BFS and DFS in terms of when to use each?
4. What is memoisation and how does it relate to dynamic programming?
5. When would you use a heap instead of sorting?
6. What is the space complexity of merge sort vs quick sort?
7. What is the two-pointer technique and what problems does it solve?
8. What is a sliding window and when is it applicable?
9. What does Dijkstra's algorithm assume about edge weights?
10. What is the time complexity of inserting into a BST in the worst case?
