# Module 04 — Object-Oriented Programming

> **Level:** Intermediate | **Estimated Time:** 8 hours | **Prerequisites:** Modules 01–03

---

## Learning Objectives

By the end of this module you will be able to:
- Design classes with appropriate attributes and methods
- Apply all four OOP pillars: Encapsulation, Abstraction, Inheritance, Polymorphism
- Use `@property`, `@classmethod`, and `@staticmethod` correctly
- Implement dunder (magic) methods for operator overloading and protocol compliance
- Apply SOLID principles to class design
- Use `dataclasses` and `abc` (Abstract Base Classes)
- Understand `__slots__` for memory optimization

---

## 4.1 Classes and Objects

### Conceptual Foundation

A **class** is a blueprint. An **object** (instance) is a concrete entity created from that blueprint. OOP models the world as interacting objects that have state (attributes) and behaviour (methods).

```python
class BankAccount:
    """
    A simple bank account with deposit, withdrawal, and balance tracking.

    Demonstrates encapsulation: internal state is protected from direct access.
    """

    # Class variable — shared across ALL instances
    interest_rate: float = 0.05

    def __init__(self, owner: str, initial_balance: float = 0.0) -> None:
        """Initialize account with owner name and optional starting balance."""
        self.owner = owner                     # public attribute
        self._balance = initial_balance        # protected (by convention)
        self.__transaction_log: list[str] = [] # private (name-mangled)

    # --- Properties (controlled attribute access) ---

    @property
    def balance(self) -> float:
        """Current account balance (read-only)."""
        return self._balance

    # --- Public methods ---

    def deposit(self, amount: float) -> None:
        """Add funds to the account."""
        if amount <= 0:
            raise ValueError(f"Deposit amount must be positive, got {amount}")
        self._balance += amount
        self.__transaction_log.append(f"Deposit: +${amount:.2f}")

    def withdraw(self, amount: float) -> None:
        """Remove funds from the account."""
        if amount <= 0:
            raise ValueError(f"Withdrawal amount must be positive, got {amount}")
        if amount > self._balance:
            raise ValueError(f"Insufficient funds: balance={self._balance:.2f}, requested={amount:.2f}")
        self._balance -= amount
        self.__transaction_log.append(f"Withdrawal: -${amount:.2f}")

    def apply_interest(self) -> None:
        """Apply the class-level interest rate to the current balance."""
        interest = self._balance * self.interest_rate
        self._balance += interest
        self.__transaction_log.append(f"Interest: +${interest:.2f}")

    def get_statement(self) -> str:
        """Return a formatted account statement."""
        lines = [f"Account: {self.owner}", f"Balance: ${self._balance:.2f}", "---"]
        lines.extend(self.__transaction_log)
        return "\n".join(lines)

    # --- Class methods and static methods ---

    @classmethod
    def from_dict(cls, data: dict) -> "BankAccount":
        """Alternative constructor: create an account from a dictionary."""
        return cls(owner=data["owner"], initial_balance=data.get("balance", 0.0))

    @staticmethod
    def is_valid_amount(amount: float) -> bool:
        """Validate that an amount is a positive number. No instance/class needed."""
        return isinstance(amount, (int, float)) and amount > 0

    # --- Dunder methods ---

    def __repr__(self) -> str:
        return f"BankAccount(owner={self.owner!r}, balance={self._balance:.2f})"

    def __str__(self) -> str:
        return f"{self.owner}'s account: ${self._balance:.2f}"

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, BankAccount):
            return NotImplemented
        return self.owner == other.owner and self._balance == other._balance


# --- Usage ---
account = BankAccount("Alice", 1000.0)
account.deposit(500.0)
account.withdraw(200.0)
account.apply_interest()
print(account.get_statement())
print(repr(account))
print(BankAccount.is_valid_amount(100))   # True
account2 = BankAccount.from_dict({"owner": "Bob", "balance": 500})
```

---

## 4.2 Properties — Controlled Attribute Access

```python
class Temperature:
    """
    Temperature in Celsius with automatic Fahrenheit conversion.
    Demonstrates the @property pattern for computed attributes.
    """

    def __init__(self, celsius: float = 0.0) -> None:
        self.celsius = celsius    # triggers the setter below

    @property
    def celsius(self) -> float:
        return self._celsius

    @celsius.setter
    def celsius(self, value: float) -> None:
        if value < -273.15:
            raise ValueError(f"Temperature below absolute zero: {value}")
        self._celsius = value

    @property
    def fahrenheit(self) -> float:
        """Computed property — no setter needed (derived value)."""
        return self._celsius * 9 / 5 + 32

    @property
    def kelvin(self) -> float:
        return self._celsius + 273.15

t = Temperature(100)
print(t.fahrenheit)   # 212.0
t.celsius = -50
print(t.kelvin)       # 223.15
# t.celsius = -300    # raises ValueError
```

---

## 4.3 Inheritance and Polymorphism

```python
from abc import ABC, abstractmethod

class Shape(ABC):
    """
    Abstract base class for all geometric shapes.
    Forces subclasses to implement area() and perimeter().
    """

    def __init__(self, color: str = "white") -> None:
        self.color = color

    @abstractmethod
    def area(self) -> float:
        """Return the area of this shape."""
        ...

    @abstractmethod
    def perimeter(self) -> float:
        """Return the perimeter of this shape."""
        ...

    def describe(self) -> str:
        """Describe the shape — uses polymorphic area() and perimeter()."""
        return (f"{self.__class__.__name__} ({self.color}): "
                f"area={self.area():.2f}, perimeter={self.perimeter():.2f}")

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(color={self.color!r})"


class Circle(Shape):
    import math

    def __init__(self, radius: float, color: str = "white") -> None:
        super().__init__(color)
        self.radius = radius

    def area(self) -> float:
        import math
        return math.pi * self.radius ** 2

    def perimeter(self) -> float:
        import math
        return 2 * math.pi * self.radius


class Rectangle(Shape):
    def __init__(self, width: float, height: float, color: str = "white") -> None:
        super().__init__(color)
        self.width = width
        self.height = height

    def area(self) -> float:
        return self.width * self.height

    def perimeter(self) -> float:
        return 2 * (self.width + self.height)


class Square(Rectangle):
    """A Square is a special Rectangle — demonstrates inheritance hierarchy."""

    def __init__(self, side: float, color: str = "white") -> None:
        super().__init__(side, side, color)  # reuse Rectangle.__init__

    @property
    def side(self) -> float:
        return self.width

    @side.setter
    def side(self, value: float) -> None:
        self.width = value
        self.height = value


# Polymorphism in action
shapes: list[Shape] = [
    Circle(5, "red"),
    Rectangle(4, 6, "blue"),
    Square(3, "green"),
]

# Each shape responds to describe() differently — same interface, different behavior
for shape in shapes:
    print(shape.describe())

# Total area — works regardless of shape type
total_area = sum(s.area() for s in shapes)
print(f"Total area: {total_area:.2f}")
```

### Multiple Inheritance and MRO

```python
class Flyable:
    def fly(self) -> str:
        return "I can fly!"

class Swimmable:
    def swim(self) -> str:
        return "I can swim!"

class Duck(Flyable, Swimmable):
    def quack(self) -> str:
        return "Quack!"

duck = Duck()
print(duck.fly())    # I can fly!
print(duck.swim())   # I can swim!
print(duck.quack())  # Quack!

# Method Resolution Order — Python uses C3 linearisation
print(Duck.__mro__)
# (<class 'Duck'>, <class 'Flyable'>, <class 'Swimmable'>, <class 'object'>)
```

---

## 4.4 Dunder (Magic) Methods

Dunder methods let your objects behave like built-in Python types.

```python
from __future__ import annotations
import math

class Vector:
    """
    2D vector with full operator overloading.
    Demonstrates: __add__, __mul__, __abs__, __eq__, __len__, __iter__, __repr__
    """

    def __init__(self, x: float, y: float) -> None:
        self.x = x
        self.y = y

    # Representation
    def __repr__(self) -> str:
        return f"Vector({self.x}, {self.y})"

    def __str__(self) -> str:
        return f"({self.x}, {self.y})"

    # Arithmetic
    def __add__(self, other: Vector) -> Vector:
        return Vector(self.x + other.x, self.y + other.y)

    def __sub__(self, other: Vector) -> Vector:
        return Vector(self.x - other.x, self.y - other.y)

    def __mul__(self, scalar: float) -> Vector:
        return Vector(self.x * scalar, self.y * scalar)

    def __rmul__(self, scalar: float) -> Vector:
        return self.__mul__(scalar)   # support scalar * vector

    def __truediv__(self, scalar: float) -> Vector:
        if scalar == 0:
            raise ZeroDivisionError("Cannot divide vector by zero")
        return Vector(self.x / scalar, self.y / scalar)

    def __neg__(self) -> Vector:
        return Vector(-self.x, -self.y)

    # Comparison
    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Vector):
            return NotImplemented
        return math.isclose(self.x, other.x) and math.isclose(self.y, other.y)

    def __abs__(self) -> float:
        """Magnitude of the vector."""
        return math.sqrt(self.x ** 2 + self.y ** 2)

    # Container protocol
    def __len__(self) -> int:
        return 2

    def __iter__(self):
        yield self.x
        yield self.y

    def __getitem__(self, index: int) -> float:
        return (self.x, self.y)[index]

    # Hashing (needed if __eq__ is defined and want to use in sets/dicts)
    def __hash__(self) -> int:
        return hash((self.x, self.y))

    # Custom method
    def dot(self, other: Vector) -> float:
        """Dot product."""
        return self.x * other.x + self.y * other.y

    def normalize(self) -> Vector:
        """Return unit vector."""
        mag = abs(self)
        if mag == 0:
            raise ValueError("Cannot normalize zero vector")
        return self / mag


v1 = Vector(3, 4)
v2 = Vector(1, 2)

print(v1 + v2)         # (4, 6)
print(v1 - v2)         # (2, 2)
print(v1 * 2)          # (6, 8)
print(3 * v1)          # (9, 12)
print(abs(v1))         # 5.0
print(list(v1))        # [3, 4]
print(v1[0], v1[1])    # 3 4
print(v1.dot(v2))      # 11.0
print(v1.normalize())  # (0.6, 0.8)
```

---

## 4.5 Dataclasses

`dataclasses` auto-generate `__init__`, `__repr__`, `__eq__`, and more.

```python
from dataclasses import dataclass, field, asdict, astuple
from typing import ClassVar

@dataclass
class Product:
    """
    E-commerce product with auto-generated boilerplate.
    Uses dataclass to eliminate __init__/__repr__/__eq__ boilerplate.
    """
    name: str
    price: float
    category: str
    tags: list[str] = field(default_factory=list)
    in_stock: bool = True
    _discount: float = field(default=0.0, repr=False)  # not shown in repr

    # Class variable — excluded from __init__
    TAX_RATE: ClassVar[float] = 0.08

    def __post_init__(self) -> None:
        """Validation after auto-generated __init__."""
        if self.price < 0:
            raise ValueError(f"Price cannot be negative: {self.price}")

    @property
    def discounted_price(self) -> float:
        return self.price * (1 - self._discount)

    @property
    def price_with_tax(self) -> float:
        return self.discounted_price * (1 + self.TAX_RATE)


@dataclass(frozen=True)   # immutable — generates __hash__ automatically
class Point:
    x: float
    y: float

    def distance_to(self, other: "Point") -> float:
        return math.sqrt((self.x - other.x)**2 + (self.y - other.y)**2)


p = Product("Python Book", 39.99, "Education", tags=["python", "programming"])
print(p)            # Product(name='Python Book', price=39.99, ...)
print(asdict(p))    # dict representation

pt = Point(1.0, 2.0)
print(pt.distance_to(Point(4.0, 6.0)))  # 5.0
```

---

## 4.6 SOLID Principles in Python

### S — Single Responsibility
```python
# BAD: one class does too much
class UserManager:
    def get_user(self, user_id: int): ...
    def save_to_db(self, user): ...
    def send_email(self, user, message: str): ...
    def generate_pdf_report(self, user): ...

# GOOD: each class has one reason to change
class UserRepository:
    def get(self, user_id: int): ...
    def save(self, user): ...

class EmailService:
    def send(self, to: str, message: str): ...

class ReportGenerator:
    def generate_pdf(self, data: dict): ...
```

### O — Open/Closed
```python
# Open for extension, closed for modification
from abc import ABC, abstractmethod

class Discount(ABC):
    @abstractmethod
    def apply(self, price: float) -> float: ...

class PercentageDiscount(Discount):
    def __init__(self, percent: float) -> None:
        self.percent = percent
    def apply(self, price: float) -> float:
        return price * (1 - self.percent / 100)

class FixedDiscount(Discount):
    def __init__(self, amount: float) -> None:
        self.amount = amount
    def apply(self, price: float) -> float:
        return max(0.0, price - self.amount)

# Add new discount types WITHOUT modifying existing code
class BuyOneGetOne(Discount):
    def apply(self, price: float) -> float:
        return price / 2
```

### L — Liskov Substitution
```python
# Subclasses must be substitutable for their base class
class Bird(ABC):
    @abstractmethod
    def move(self) -> str: ...

class FlyingBird(Bird):
    def move(self) -> str:
        return "flying"

class SwimmingBird(Bird):
    def move(self) -> str:
        return "swimming"

# Don't add fly() to Bird if Penguin can't fly!
# Split the interface instead.
```

### D — Dependency Inversion
```python
# Depend on abstractions, not concretions
class NotificationSender(ABC):
    @abstractmethod
    def send(self, recipient: str, message: str) -> None: ...

class EmailSender(NotificationSender):
    def send(self, recipient: str, message: str) -> None:
        print(f"Email to {recipient}: {message}")

class SMSSender(NotificationSender):
    def send(self, recipient: str, message: str) -> None:
        print(f"SMS to {recipient}: {message}")

class UserService:
    def __init__(self, sender: NotificationSender) -> None:
        self._sender = sender   # injected dependency

    def notify_user(self, user_email: str, message: str) -> None:
        self._sender.send(user_email, message)

service = UserService(EmailSender())   # swap to SMSSender easily
service.notify_user("alice@ex.com", "Welcome!")
```

---

## Best Practices

1. **Prefer composition over inheritance** — "has-a" relationships are more flexible than "is-a".
2. **Use `@dataclass`** for pure data objects — eliminates boilerplate.
3. **Use `ABC` for interfaces** — makes expected behaviour explicit.
4. **Always implement `__repr__`** — critical for debugging.
5. **Use `@property` instead of getters/setters** — Pythonic attribute access with validation.
6. **Return `NotImplemented` (not `False`)** from `__eq__` when types don't match — allows Python to try the other operand's method.
7. **Use `__slots__`** for classes instantiated millions of times to save memory.

```python
class Point:
    __slots__ = ("x", "y")   # ~40% memory reduction, faster attribute access
    def __init__(self, x: float, y: float) -> None:
        self.x, self.y = x, y
```

---

## Exercises

### Exercise 4.1 — Stack Implementation (Intermediate)
Implement a generic `Stack[T]` class using a list internally. Support: `push`, `pop`, `peek`, `is_empty`, `size`, `__len__`, `__repr__`, `__contains__`.

**Solution:**
```python
from typing import TypeVar, Generic

T = TypeVar("T")

class Stack(Generic[T]):
    """LIFO stack with full Python protocol support."""

    def __init__(self) -> None:
        self._data: list[T] = []

    def push(self, item: T) -> None:
        self._data.append(item)

    def pop(self) -> T:
        if self.is_empty():
            raise IndexError("pop from empty stack")
        return self._data.pop()

    def peek(self) -> T:
        if self.is_empty():
            raise IndexError("peek at empty stack")
        return self._data[-1]

    def is_empty(self) -> bool:
        return len(self._data) == 0

    def __len__(self) -> int:
        return len(self._data)

    def __contains__(self, item: T) -> bool:
        return item in self._data

    def __repr__(self) -> str:
        return f"Stack({self._data!r})"

s: Stack[int] = Stack()
s.push(1); s.push(2); s.push(3)
print(s)         # Stack([1, 2, 3])
print(s.peek())  # 3
print(s.pop())   # 3
print(2 in s)    # True
print(len(s))    # 2
```

---

### Exercise 4.2 — Linked List (Advanced)
Implement a singly `LinkedList` with `append`, `prepend`, `delete`, `find`, `__iter__`, and `__len__`.

**Solution:**
```python
from __future__ import annotations
from typing import Optional, Iterator, TypeVar

T = TypeVar("T")

class Node:
    def __init__(self, data) -> None:
        self.data = data
        self.next: Optional[Node] = None

class LinkedList:
    """Singly linked list with full Python iteration support."""

    def __init__(self) -> None:
        self._head: Optional[Node] = None
        self._size: int = 0

    def append(self, data) -> None:
        new_node = Node(data)
        if not self._head:
            self._head = new_node
        else:
            current = self._head
            while current.next:
                current = current.next
            current.next = new_node
        self._size += 1

    def prepend(self, data) -> None:
        new_node = Node(data)
        new_node.next = self._head
        self._head = new_node
        self._size += 1

    def delete(self, data) -> bool:
        if not self._head:
            return False
        if self._head.data == data:
            self._head = self._head.next
            self._size -= 1
            return True
        current = self._head
        while current.next:
            if current.next.data == data:
                current.next = current.next.next
                self._size -= 1
                return True
            current = current.next
        return False

    def find(self, data) -> Optional[Node]:
        current = self._head
        while current:
            if current.data == data:
                return current
            current = current.next
        return None

    def __iter__(self) -> Iterator:
        current = self._head
        while current:
            yield current.data
            current = current.next

    def __len__(self) -> int:
        return self._size

    def __repr__(self) -> str:
        return " → ".join(str(x) for x in self) + " → None"

ll = LinkedList()
ll.append(1); ll.append(2); ll.append(3)
ll.prepend(0)
print(ll)           # 0 → 1 → 2 → 3 → None
ll.delete(2)
print(ll)           # 0 → 1 → 3 → None
print(list(ll))     # [0, 1, 3]
print(len(ll))      # 3
```

---

## Module Summary

| Concept | Key Takeaway |
|---------|-------------|
| `__init__` | Initializer — sets up instance state |
| `@property` | Controlled attribute access without breaking interface |
| `@classmethod` | Alternative constructors; receives `cls`, not `self` |
| `@staticmethod` | Utility function logically grouped with the class |
| Inheritance | Use `super()` explicitly; be careful with multiple inheritance |
| `ABC` + `@abstractmethod` | Enforce a contract; cannot instantiate abstract classes |
| Dunder methods | Make objects behave like built-ins; always return `NotImplemented` for unknown types |
| `@dataclass` | Eliminates `__init__/__repr__/__eq__` boilerplate |
| SOLID | Guidelines, not laws — apply with judgment |

---

## Quiz

1. What is the difference between `@classmethod` and `@staticmethod`?
2. Why should `__eq__` return `NotImplemented` instead of `False` for unknown types?
3. What does `super()` do in a class with multiple inheritance?
4. What is the purpose of `__post_init__` in a dataclass?
5. Why can't you instantiate an `ABC` that has abstract methods?
6. What is name mangling? What does `self.__x` become internally?
7. What is the difference between `__str__` and `__repr__`?
8. How does `@property` differ from a regular method?
9. What are `__slots__` and when should you use them?
10. In the Liskov Substitution Principle, what rule must subclasses satisfy?
