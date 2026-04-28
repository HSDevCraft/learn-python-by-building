# Module 04 — Object-Oriented Programming

> **Level:** Intermediate | **Estimated Time:** 8 hours | **Prerequisites:** Modules 01–03

---

## Learning Objectives

By the end of this module you will be able to:
- Explain how Python stores objects in memory and what `self` really is
- Apply all four OOP pillars: Encapsulation, Abstraction, Inheritance, Polymorphism
- Use `@property`, `@classmethod`, and `@staticmethod` correctly and choose between them
- Implement dunder (magic) methods for operator overloading and protocol compliance
- Apply all five SOLID principles with realistic code examples
- Use `dataclasses` and `abc` (Abstract Base Classes) in production code
- Apply classic design patterns: Repository, Strategy, Factory, Observer
- Design a real system (e-commerce, notification system) using OOP

---

## The Big Picture — Why OOP?

OOP is a **way of organizing code around data + behaviour** rather than procedures. It shines when:
- A system has many interacting entities with **state** (a User, Order, Product)
- You want to **enforce contracts** between components (interfaces/ABCs)
- You want to **extend** behaviour without changing working code (Open/Closed)

**Analogy:** A class is like a cookie cutter (the blueprint). An object is a cookie (the real thing). Many cookies can be made from one cutter, each with its own state (e.g., different icing).

---

## How Python Stores Objects in Memory

```
account = BankAccount("Alice", 1000.0)

Memory layout:
┌──────────────────────────────────────────────┐
│ Stack frame (local scope)                     │
│   account → [ref] ──────────────────────┐    │
└─────────────────────────────────────────┼────┘
                                          ▼
┌──────────────────────────────────────────────┐
│ Heap — BankAccount instance                   │
│   __class__   → BankAccount (class object)    │
│   __dict__    → { "owner":    "Alice",        │
│                   "_balance": 1000.0,          │
│                   "__transaction_log": [] }    │
└──────────────────────────────────────────────┘

When you call account.deposit(500):
  Python looks up 'deposit' in account.__dict__  → not found
  Then looks in type(account).__dict__           → found in BankAccount
  Calls BankAccount.deposit(account, 500)
  ↑ This is what 'self' is — Python passes the instance automatically!
```

---

## 4.1 Classes and Objects

```python
from __future__ import annotations
from typing import ClassVar
import math

class BankAccount:
    """
    A bank account demonstrating encapsulation, class vs instance variables,
    @property, @classmethod, @staticmethod, and dunder methods.

    Encapsulation analogy: the account is like an ATM machine.
    You interact through defined buttons (methods), not by directly
    manipulating internal circuits (private attributes).
    """

    # ── Class variable: shared by ALL instances ───────────────────────────
    # Changing BankAccount.interest_rate affects all existing accounts
    interest_rate: ClassVar[float] = 0.05

    # ── __init__: called when you do BankAccount("Alice", 1000) ──────────
    def __init__(self, owner: str, initial_balance: float = 0.0) -> None:
        self.owner = owner                        # public: anyone can read/write
        self._balance = initial_balance           # protected: "please don't touch directly"
        self.__tx_log: list[str] = []             # private: name-mangled to _BankAccount__tx_log

    # ── @property: attribute-style access with hidden validation ──────────
    # Called when you write: account.balance  (no parentheses — looks like attribute)
    @property
    def balance(self) -> float:
        """Read-only balance — no setter means external code cannot assign to it."""
        return self._balance

    # ── Instance methods ─────────────────────────────────────────────────
    def deposit(self, amount: float) -> "BankAccount":
        """Deposit money. Returns self for method chaining."""
        if amount <= 0:
            raise ValueError(f"Deposit must be positive, got {amount}")
        self._balance += amount
        self.__tx_log.append(f"+${amount:.2f}")
        return self                               # enables chaining: account.deposit(100).deposit(50)

    def withdraw(self, amount: float) -> "BankAccount":
        """Withdraw money. Raises ValueError if insufficient funds."""
        if amount <= 0:
            raise ValueError(f"Withdrawal must be positive, got {amount}")
        if amount > self._balance:
            raise ValueError(f"Insufficient funds: have ${self._balance:.2f}, need ${amount:.2f}")
        self._balance -= amount
        self.__tx_log.append(f"-${amount:.2f}")
        return self

    def apply_interest(self) -> "BankAccount":
        """Apply class-level interest rate to balance."""
        interest = self._balance * self.interest_rate
        self._balance += interest
        self.__tx_log.append(f"Interest +${interest:.2f}")
        return self

    def statement(self) -> str:
        """Return formatted account statement."""
        header = f"{'Account Statement':=^40}\nOwner: {self.owner}\nBalance: ${self._balance:.2f}\n---"
        return "\n".join([header] + self.__tx_log)

    # ── @classmethod: alternative constructors — gets `cls`, not `self` ───
    # Use @classmethod when you need to create an instance in a different way
    @classmethod
    def from_dict(cls, data: dict) -> "BankAccount":
        """Create an account from a dictionary (e.g., from a database row)."""
        return cls(owner=data["owner"], initial_balance=data.get("balance", 0.0))

    @classmethod
    def from_json_string(cls, json_str: str) -> "BankAccount":
        """Create an account from a JSON string."""
        import json
        return cls.from_dict(json.loads(json_str))

    # ── @staticmethod: utility function grouped with the class ────────────
    # Use @staticmethod when the logic belongs conceptually to the class
    # but doesn't need access to any instance or class state
    @staticmethod
    def is_valid_amount(amount: float) -> bool:
        """Return True if amount is a valid positive number."""
        return isinstance(amount, (int, float)) and amount > 0

    # ── Dunder methods: make the object behave like a built-in ───────────
    def __repr__(self) -> str:
        """repr() → unambiguous string for developers and debugging."""
        return f"BankAccount(owner={self.owner!r}, balance={self._balance:.2f})"

    def __str__(self) -> str:
        """str() → human-readable string for end users."""
        return f"{self.owner}'s account: ${self._balance:.2f}"

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, BankAccount):
            return NotImplemented   # not False! lets Python try the other object
        return self.owner == other.owner and math.isclose(self._balance, other._balance)

    def __lt__(self, other: "BankAccount") -> bool:
        """Allows sorting accounts by balance."""
        return self._balance < other._balance

    def __bool__(self) -> bool:
        """Account is truthy if balance > 0."""
        return self._balance > 0


# ── Demo ─────────────────────────────────────────────────────────────────
account = BankAccount("Alice", 1000.0)
account.deposit(500.0).withdraw(200.0).apply_interest()  # method chaining!
print(account.statement())
print(repr(account))

account2 = BankAccount.from_dict({"owner": "Bob", "balance": 200})
accounts = sorted([account, account2])    # works because we defined __lt__
print([str(a) for a in accounts])
```

---

## 4.2 Properties — Controlled Attribute Access

```python
class Temperature:
    """
    Temperature in Celsius with automatic Fahrenheit/Kelvin conversion.

    WHY @property? In Python, you start with a plain attribute:
        self.celsius = value
    If later you need validation, you convert it to a @property.
    External code using t.celsius = 100 doesn't change — NO breaking change.
    This is the 'uniform access principle'.
    """

    def __init__(self, celsius: float = 0.0) -> None:
        self.celsius = celsius    # ← this triggers the @celsius.setter!

    @property
    def celsius(self) -> float:
        """Return temperature in Celsius."""
        return self._celsius      # stores in _celsius to avoid infinite recursion

    @celsius.setter
    def celsius(self, value: float) -> None:
        """Validate before setting — called by both __init__ and direct assignment."""
        if value < -273.15:
            raise ValueError(f"Below absolute zero: {value}°C")
        self._celsius = value     # stores the actual value in a private attribute

    @property
    def fahrenheit(self) -> float:
        """Computed/derived property — no setter because it's derived from celsius."""
        return self._celsius * 9 / 5 + 32

    @fahrenheit.setter
    def fahrenheit(self, value: float) -> None:
        """Allow setting via Fahrenheit — converts and validates through celsius setter."""
        self.celsius = (value - 32) * 5 / 9    # delegates validation to celsius setter

    @property
    def kelvin(self) -> float:
        return self._celsius + 273.15

    def __repr__(self) -> str:
        return f"Temperature({self._celsius}°C / {self.fahrenheit}°F / {self.kelvin}K)"


t = Temperature(100)
print(t)                # Temperature(100°C / 212.0°F / 373.15K)
t.fahrenheit = 32       # uses the fahrenheit setter
print(t.celsius)        # 0.0
```

---

## 4.3 Inheritance, ABCs, and Polymorphism

### Abstract Base Classes — Enforcing Contracts

```python
from abc import ABC, abstractmethod
import math

class Shape(ABC):
    """
    Abstract base class — cannot be instantiated directly.
    Acts as a contract: all subclasses MUST implement area() and perimeter().

    System Design use: ABCs define interfaces between components.
    A rendering engine can work with any Shape without knowing its type.
    """

    def __init__(self, color: str = "white") -> None:
        self.color = color

    @abstractmethod
    def area(self) -> float:
        """Return the area of the shape."""
        ...          # ellipsis is conventional for abstract method bodies

    @abstractmethod
    def perimeter(self) -> float:
        """Return the perimeter of the shape."""
        ...

    def describe(self) -> str:
        """Concrete method — uses polymorphic area() and perimeter()."""
        return (f"{type(self).__name__}({self.color}): "
                f"area={self.area():.2f}, perimeter={self.perimeter():.2f}")

    def __repr__(self) -> str:
        return f"{type(self).__name__}(color={self.color!r})"


class Circle(Shape):
    def __init__(self, radius: float, color: str = "white") -> None:
        super().__init__(color)     # always call super().__init__() first!
        self.radius = radius

    def area(self) -> float:
        return math.pi * self.radius ** 2

    def perimeter(self) -> float:
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


class Triangle(Shape):
    def __init__(self, a: float, b: float, c: float, color: str = "white") -> None:
        super().__init__(color)
        self.a, self.b, self.c = a, b, c

    def area(self) -> float:
        s = (self.a + self.b + self.c) / 2      # Heron's formula
        return math.sqrt(s * (s-self.a) * (s-self.b) * (s-self.c))

    def perimeter(self) -> float:
        return self.a + self.b + self.c


# ── Polymorphism in action ───────────────────────────────────────────────
shapes: list[Shape] = [Circle(5), Rectangle(4, 6), Triangle(3, 4, 5)]

# This loop works for ANY Shape — past or future — without modification
for shape in shapes:
    print(shape.describe())

total_area = sum(s.area() for s in shapes)   # works regardless of shape types
print(f"Total: {total_area:.2f}")

# ── Multiple inheritance and MRO (C3 Linearisation) ─────────────────────
class Serializable:
    def to_dict(self) -> dict:
        return {k: v for k, v in self.__dict__.items() if not k.startswith("_")}

class Drawable:
    def draw(self) -> str:
        return f"Drawing {type(self).__name__}"

class DrawableCircle(Circle, Serializable, Drawable):
    """A Circle that can also be drawn and serialized."""
    pass

dc = DrawableCircle(5, "red")
print(dc.draw())            # Drawing DrawableCircle
print(dc.to_dict())         # {'color': 'red', 'radius': 5}
print(DrawableCircle.__mro__)  # Shows full resolution order
```

---

## 4.4 Dunder (Magic) Methods — Making Objects Feel Native

```python
from __future__ import annotations
import math
from typing import Iterator

class Vector:
    """
    2D vector with full Python operator protocol.

    WHY dunders? They let your objects work with Python's built-in
    operators (+, -, *, abs(), len(), in, ==) and built-in functions
    (repr(), str(), bool(), hash()) without special-casing.
    """

    def __init__(self, x: float, y: float) -> None:
        self.x = x
        self.y = y

    # ── Representation ───────────────────────────────────────────────────
    def __repr__(self) -> str:
        """For developers: copy-pasteable, unambiguous."""
        return f"Vector({self.x}, {self.y})"

    def __str__(self) -> str:
        """For users: readable."""
        return f"({self.x}, {self.y})"

    # ── Arithmetic operators ─────────────────────────────────────────────
    def __add__(self, other: Vector) -> Vector:
        """v1 + v2 — called on the LEFT operand."""
        return Vector(self.x + other.x, self.y + other.y)

    def __sub__(self, other: Vector) -> Vector:
        return Vector(self.x - other.x, self.y - other.y)

    def __mul__(self, scalar: float) -> Vector:
        """v * 3 — left operand is the vector."""
        return Vector(self.x * scalar, self.y * scalar)

    def __rmul__(self, scalar: float) -> Vector:
        """3 * v — Python calls this when LEFT operand doesn't handle it."""
        return self.__mul__(scalar)

    def __truediv__(self, scalar: float) -> Vector:
        if scalar == 0:
            raise ZeroDivisionError("Cannot divide vector by zero")
        return Vector(self.x / scalar, self.y / scalar)

    def __neg__(self) -> Vector:
        """-v → negate both components."""
        return Vector(-self.x, -self.y)

    # ── Comparison ───────────────────────────────────────────────────────
    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Vector):
            return NotImplemented   # ← MUST be NotImplemented, not False
        return math.isclose(self.x, other.x) and math.isclose(self.y, other.y)

    def __hash__(self) -> int:
        """Needed because we defined __eq__. Allows use in sets and as dict keys."""
        return hash((round(self.x, 10), round(self.y, 10)))

    # ── Numeric/container protocol ───────────────────────────────────────
    def __abs__(self) -> float:
        """abs(v) → magnitude/length of the vector."""
        return math.sqrt(self.x ** 2 + self.y ** 2)

    def __bool__(self) -> bool:
        """bool(v) → False only for the zero vector."""
        return abs(self) != 0

    def __len__(self) -> int:
        """len(v) → always 2 for a 2D vector."""
        return 2

    def __iter__(self) -> Iterator[float]:
        """for component in v: — enables unpacking: x, y = v"""
        yield self.x
        yield self.y

    def __getitem__(self, index: int) -> float:
        """v[0] → x, v[1] → y."""
        return (self.x, self.y)[index]

    # ── Custom methods ───────────────────────────────────────────────────
    def dot(self, other: Vector) -> float:
        """Dot product: measures how aligned two vectors are."""
        return self.x * other.x + self.y * other.y

    def normalize(self) -> Vector:
        """Return a unit vector (magnitude = 1) in the same direction."""
        mag = abs(self)
        if mag == 0:
            raise ValueError("Cannot normalize zero vector")
        return self / mag


v1 = Vector(3, 4)
v2 = Vector(1, 2)
print(v1 + v2)          # (4, 6)
print(3 * v1)           # (9, 12)   — uses __rmul__
print(abs(v1))          # 5.0
x, y = v1               # unpacking via __iter__
print(x, y)             # 3 4
print(v1 in {v1, v2})   # True — uses __hash__ and __eq__
```

---

## 4.5 Dataclasses — Eliminate Boilerplate

```python
from dataclasses import dataclass, field, asdict
from typing import ClassVar
import math

@dataclass                          # auto-generates __init__, __repr__, __eq__
class Product:
    """
    E-commerce product. Dataclass eliminates ~20 lines of boilerplate.

    Without @dataclass you'd need to write:
        def __init__(self, name, price, category, tags=None, in_stock=True): ...
        def __repr__(self): ...
        def __eq__(self, other): ...
    """
    name: str                       # required field — must come first
    price: float
    category: str
    tags: list[str] = field(default_factory=list)  # mutable default MUST use field()
    in_stock: bool = True           # optional with default

    TAX_RATE: ClassVar[float] = 0.08   # class variable — NOT included in __init__

    def __post_init__(self) -> None:
        """Runs after the auto-generated __init__ — use for validation."""
        if self.price < 0:
            raise ValueError(f"Price cannot be negative: {self.price}")
        if not self.name.strip():
            raise ValueError("Product name cannot be empty")

    @property
    def price_with_tax(self) -> float:
        return self.price * (1 + self.TAX_RATE)

    def add_tag(self, tag: str) -> "Product":
        self.tags.append(tag)
        return self


@dataclass(frozen=True)             # immutable — generates __hash__ too
class Point:
    """Immutable 2D point — can be used as a dict key."""
    x: float
    y: float

    def distance_to(self, other: "Point") -> float:
        return math.sqrt((self.x - other.x)**2 + (self.y - other.y)**2)


@dataclass(order=True)              # generates __lt__, __le__, __gt__, __ge__
class Employee:
    """Sortable employee — @dataclass(order=True) compares field by field."""
    sort_index: float = field(init=False, repr=False)   # computed in __post_init__
    name: str
    department: str
    salary: float

    def __post_init__(self):
        self.sort_index = self.salary   # sort by salary


p = Product("Python Book", 39.99, "Education")
p.add_tag("python").add_tag("beginner")
print(p)                    # Product(name='Python Book', price=39.99, ...)
print(asdict(p))            # {'name': 'Python Book', 'price': 39.99, ...}
print(p.price_with_tax)     # 43.19...

employees = [Employee("Bob", "Eng", 90000), Employee("Alice", "Eng", 95000)]
print(sorted(employees))    # Alice first (higher salary)
```

---

## 4.6 SOLID Principles — Writing Maintainable Systems

### S — Single Responsibility Principle

*A class should have ONE reason to change.*

```python
# ── BAD: UserManager does everything ─────────────────────────────────────
class UserManagerBad:
    def get_user(self, user_id: int): ...
    def save_user(self, user): ...
    def send_welcome_email(self, user): ...
    def export_to_csv(self, users): ...
    # If email logic changes → this class changes
    # If DB schema changes  → this class changes
    # If CSV format changes → this class changes
    # → 3 different reasons to change!

# ── GOOD: Separate concerns ───────────────────────────────────────────────
class UserRepository:
    """Handles persistence ONLY — one reason to change: DB schema changes."""
    def find(self, user_id: int) -> dict: ...
    def save(self, user: dict) -> None: ...

class EmailService:
    """Handles emails ONLY — changes when email templates/provider changes."""
    def send_welcome(self, email: str) -> None: ...

class ReportExporter:
    """Handles exports ONLY — changes when output format changes."""
    def to_csv(self, users: list) -> str: ...
```

### O — Open/Closed Principle

*Open for extension, closed for modification.*

```python
from abc import ABC, abstractmethod

class PricingStrategy(ABC):
    """Abstract strategy — add new pricing rules WITHOUT touching existing code."""

    @abstractmethod
    def calculate(self, base_price: float) -> float:
        ...

class RegularPrice(PricingStrategy):
    def calculate(self, base_price: float) -> float:
        return base_price

class PercentageDiscount(PricingStrategy):
    def __init__(self, percent: float) -> None:
        self.percent = percent
    def calculate(self, base_price: float) -> float:
        return base_price * (1 - self.percent / 100)

class FixedDiscount(PricingStrategy):
    def __init__(self, amount: float) -> None:
        self.amount = amount
    def calculate(self, base_price: float) -> float:
        return max(0.0, base_price - self.amount)

class SeasonalDiscount(PricingStrategy):
    """NEW discount type — no existing code modified!"""
    def __init__(self, multiplier: float) -> None:
        self.multiplier = multiplier
    def calculate(self, base_price: float) -> float:
        return base_price * self.multiplier

class OrderPricer:
    """Works with ANY PricingStrategy — doesn't know or care which one."""
    def __init__(self, strategy: PricingStrategy) -> None:
        self._strategy = strategy

    def get_price(self, base_price: float) -> float:
        return self._strategy.calculate(base_price)

pricer = OrderPricer(PercentageDiscount(20))
print(pricer.get_price(100))   # 80.0
pricer = OrderPricer(SeasonalDiscount(0.5))
print(pricer.get_price(100))   # 50.0
```

### L — Liskov Substitution Principle

*Subclasses must be usable wherever their base class is expected.*

```python
# ── BAD: violates LSP ─────────────────────────────────────────────────────
class Rectangle:
    def set_width(self, w): self.width = w
    def set_height(self, h): self.height = h
    def area(self): return self.width * self.height

class SquareBad(Rectangle):
    """LSP violation: Square overrides setters to enforce width==height,
    but code expecting a Rectangle would break when width != height after setters."""
    def set_width(self, w):
        self.width = self.height = w    # silently changes height too!
    def set_height(self, h):
        self.width = self.height = h    # silently changes width too!

# ── GOOD: use composition or a clean hierarchy ───────────────────────────
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self) -> float: ...

class GoodRectangle(Shape):
    def __init__(self, w: float, h: float):
        self._w, self._h = w, h
    def area(self) -> float:
        return self._w * self._h

class GoodSquare(Shape):
    def __init__(self, side: float):
        self._side = side
    def area(self) -> float:
        return self._side ** 2
```

### I — Interface Segregation Principle

*Don't force classes to implement methods they don't need.*

```python
# ── BAD: one fat interface ───────────────────────────────────────────────
class WorkerBad(ABC):
    @abstractmethod
    def work(self) -> None: ...
    @abstractmethod
    def eat(self) -> None: ...     # Robots don't eat!
    @abstractmethod
    def sleep(self) -> None: ...   # Robots don't sleep!

# ── GOOD: split into focused interfaces ──────────────────────────────────
class Workable(ABC):
    @abstractmethod
    def work(self) -> None: ...

class Feedable(ABC):
    @abstractmethod
    def eat(self) -> None: ...

class Human(Workable, Feedable):
    def work(self) -> None: print("Human working")
    def eat(self) -> None: print("Human eating")

class Robot(Workable):
    def work(self) -> None: print("Robot working")
    # Robot doesn't implement eat() — and that's fine!
```

### D — Dependency Inversion Principle

*Depend on abstractions, not concretions.*

```python
from abc import ABC, abstractmethod

class NotificationChannel(ABC):
    """Abstraction — high-level code depends on this, not on Email/SMS classes."""

    @abstractmethod
    def send(self, recipient: str, message: str) -> None:
        ...

class EmailChannel(NotificationChannel):
    def send(self, recipient: str, message: str) -> None:
        print(f"[EMAIL] To: {recipient} | {message}")

class SMSChannel(NotificationChannel):
    def send(self, recipient: str, message: str) -> None:
        print(f"[SMS] To: {recipient} | {message}")

class SlackChannel(NotificationChannel):
    def send(self, recipient: str, message: str) -> None:
        print(f"[SLACK] @{recipient}: {message}")

class NotificationService:
    """
    High-level module — depends on the ABSTRACTION NotificationChannel.
    Can be given any channel at runtime without changing this class.
    This is also Dependency Injection — the dependency is provided externally.
    """
    def __init__(self, *channels: NotificationChannel) -> None:
        self._channels = channels

    def notify(self, recipient: str, message: str) -> None:
        for channel in self._channels:
            channel.send(recipient, message)

# Notify through multiple channels simultaneously
service = NotificationService(EmailChannel(), SlackChannel())
service.notify("alice", "Your order has shipped!")
# [EMAIL] To: alice | Your order has shipped!
# [SLACK] @alice: Your order has shipped!
```

---

## 4.7 Design Patterns in Python

### Repository Pattern — Decouple Storage from Logic

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass

@dataclass
class User:
    id: int
    name: str
    email: str

class UserRepository(ABC):
    """Abstract data access interface."""

    @abstractmethod
    def find_by_id(self, user_id: int) -> User | None: ...

    @abstractmethod
    def save(self, user: User) -> None: ...

    @abstractmethod
    def find_all(self) -> list[User]: ...

class InMemoryUserRepository(UserRepository):
    """For tests and development — no database needed."""

    def __init__(self) -> None:
        self._store: dict[int, User] = {}

    def find_by_id(self, user_id: int) -> User | None:
        return self._store.get(user_id)

    def save(self, user: User) -> None:
        self._store[user.id] = user

    def find_all(self) -> list[User]:
        return list(self._store.values())

class UserService:
    """Business logic — knows nothing about where users are stored."""

    def __init__(self, repo: UserRepository) -> None:
        self._repo = repo                        # DI: inject any compatible repo

    def register(self, name: str, email: str) -> User:
        user_id = len(self._repo.find_all()) + 1
        user = User(id=user_id, name=name, email=email)
        self._repo.save(user)
        return user

    def get_user(self, user_id: int) -> User:
        user = self._repo.find_by_id(user_id)
        if not user:
            raise ValueError(f"User {user_id} not found")
        return user

repo = InMemoryUserRepository()
service = UserService(repo)
alice = service.register("Alice", "alice@example.com")
bob   = service.register("Bob",   "bob@example.com")
print(service.get_user(1))   # User(id=1, name='Alice', email='alice@example.com')
```

### Observer Pattern — Event-Driven Systems

```python
from abc import ABC, abstractmethod
from typing import Callable

class EventEmitter:
    """
    Publish-Subscribe pattern used in:
    - GUI frameworks (button click events)
    - Server-side event systems (order placed → notify inventory, email, analytics)
    - Real-time dashboards
    """
    def __init__(self) -> None:
        self._listeners: dict[str, list[Callable]] = {}

    def on(self, event: str, callback: Callable) -> None:
        """Register a listener for an event."""
        self._listeners.setdefault(event, []).append(callback)

    def emit(self, event: str, **data) -> None:
        """Fire all listeners for an event."""
        for callback in self._listeners.get(event, []):
            callback(**data)

class OrderSystem(EventEmitter):
    """Order service that emits events — doesn't know who listens."""

    def place_order(self, order_id: str, product: str, qty: int) -> None:
        print(f"Order {order_id} placed: {qty}x {product}")
        self.emit("order_placed", order_id=order_id, product=product, qty=qty)

    def ship_order(self, order_id: str) -> None:
        print(f"Order {order_id} shipped")
        self.emit("order_shipped", order_id=order_id)

orders = OrderSystem()

# Register independent listeners — each has one responsibility
orders.on("order_placed", lambda **d: print(f"[Inventory] Reserving {d['qty']} × {d['product']}"))
orders.on("order_placed", lambda **d: print(f"[Email] Confirmation sent for {d['order_id']}"))
orders.on("order_shipped", lambda **d: print(f"[Email] Shipping notification for {d['order_id']}"))

orders.place_order("ORD-001", "Python Book", 2)
orders.ship_order("ORD-001")
```

---

## Best Practices

```python
# ── 1. __slots__: reduce memory for frequently instantiated classes ───────
class HighFrequencyPoint:
    __slots__ = ("x", "y")    # no __dict__ → ~40% memory saving
    def __init__(self, x: float, y: float) -> None:
        self.x, self.y = x, y

# ── 2. __repr__ should be copy-pasteable ─────────────────────────────────
class Config:
    def __repr__(self) -> str:
        return f"Config(host={self.host!r}, port={self.port})"  # !r adds quotes

# ── 3. @classmethod for alternative constructors ─────────────────────────
class Date:
    def __init__(self, year, month, day): ...
    @classmethod
    def from_iso_string(cls, s: str) -> "Date":
        y, m, d = s.split("-")
        return cls(int(y), int(m), int(d))

# ── 4. Composition over inheritance ──────────────────────────────────────
class Logger:
    def log(self, msg: str): print(f"[LOG] {msg}")

class Service:
    def __init__(self):
        self._logger = Logger()    # HAS-A Logger (composition)
        # NOT: class Service(Logger)  — IS-A Logger (wrong!)
```

---

## Exercises

### Exercise 4.1 — Generic Stack

```python
from typing import TypeVar, Generic

T = TypeVar("T")

class Stack(Generic[T]):
    """Type-safe LIFO stack with Python protocol support."""

    def __init__(self) -> None:
        self._data: list[T] = []

    def push(self, item: T) -> None:
        self._data.append(item)

    def pop(self) -> T:
        if not self._data:
            raise IndexError("pop from empty stack")
        return self._data.pop()

    def peek(self) -> T:
        if not self._data:
            raise IndexError("peek at empty stack")
        return self._data[-1]

    def __len__(self) -> int: return len(self._data)
    def __bool__(self) -> bool: return bool(self._data)
    def __contains__(self, item: T) -> bool: return item in self._data
    def __repr__(self) -> str: return f"Stack({self._data!r})"

s: Stack[int] = Stack()
s.push(1); s.push(2); s.push(3)
print(s.peek(), s.pop(), 2 in s, len(s))  # 3 3 True 2
```

### Exercise 4.2 — Plugin Registry (System Design)

```python
from abc import ABC, abstractmethod
from typing import Type

class Plugin(ABC):
    @abstractmethod
    def execute(self, data: str) -> str: ...
    @property
    @abstractmethod
    def name(self) -> str: ...

class PluginRegistry:
    """
    Plugin system: discover and run plugins by name.
    Used in: CLI tools, content processors, data pipelines.
    """
    _registry: dict[str, Type[Plugin]] = {}

    @classmethod
    def register(cls, plugin_cls: Type[Plugin]) -> Type[Plugin]:
        """Decorator to register a plugin class."""
        instance = plugin_cls()
        cls._registry[instance.name] = plugin_cls
        return plugin_cls

    @classmethod
    def get(cls, name: str) -> Plugin:
        if name not in cls._registry:
            raise KeyError(f"Plugin '{name}' not registered. Available: {list(cls._registry)}")
        return cls._registry[name]()

    @classmethod
    def run(cls, name: str, data: str) -> str:
        return cls.get(name).execute(data)

@PluginRegistry.register
class UpperCasePlugin(Plugin):
    @property
    def name(self) -> str: return "uppercase"
    def execute(self, data: str) -> str: return data.upper()

@PluginRegistry.register
class ReversePlugin(Plugin):
    @property
    def name(self) -> str: return "reverse"
    def execute(self, data: str) -> str: return data[::-1]

print(PluginRegistry.run("uppercase", "hello"))   # HELLO
print(PluginRegistry.run("reverse", "hello"))     # olleh
```

---

## Interview Prep — Top Questions for OOP

**Q1: What are the four pillars of OOP?**
- **Encapsulation**: Bundle data and methods; hide internal state (`_private`, `__dunder` name-mangling). Prevents external code from depending on implementation details.
- **Abstraction**: Expose only what's necessary. Use `ABC` to define contracts without implementations.
- **Inheritance**: Share and extend behavior. Use sparingly — prefer composition (has-a) over inheritance (is-a) for flexibility.
- **Polymorphism**: Same interface, different implementations. `duck typing` in Python means no explicit casting needed — if it has a `draw()` method, you can call `draw()` on it.

**Q2: What is the difference between `@classmethod`, `@staticmethod`, and instance methods?**
- **Instance method**: receives `self` (the instance). Accesses/modifies instance state. Most common.
- **`@classmethod`**: receives `cls` (the class). Used for alternative constructors (`User.from_dict()`, `User.from_csv()`). Can be called on the class or an instance.
- **`@staticmethod`**: receives neither `self` nor `cls`. A utility function that logically belongs to the class but doesn't need object state. Example: `BankAccount.validate_routing_number(num)`.

**Q3: What is `__init__` vs `__new__`?**
`__new__` creates and returns the instance (allocates memory). `__init__` initializes the already-created instance (sets attributes). You almost never override `__new__` — only needed for singletons, immutable type subclasses, metaclasses.

**Q4: Explain Python's MRO (Method Resolution Order) with diamond inheritance.**
Python uses **C3 linearization** to determine method lookup order in multiple inheritance. `ClassName.__mro__` shows the order. With `class D(B, C)` where both inherit from `A`, Python resolves: D → B → C → A, not D → B → A → C → A (which would visit A twice). `super()` follows MRO, making cooperative multiple inheritance work correctly.

**Q5: What is the difference between `__str__` and `__repr__`?**
`__repr__` is the unambiguous developer representation — should ideally be valid Python to recreate the object: `User(name='Alice', id=1)`. `__str__` is the human-readable string: `"Alice"`. `str(x)` calls `__str__` first, falls back to `__repr__`. `repr(x)` always calls `__repr__`. Always implement `__repr__` — it shows up in debuggers, logs, and the REPL.

**Q6: What are dataclasses and when would you use them vs a regular class?**
`@dataclass` auto-generates `__init__`, `__repr__`, `__eq__` from field annotations. Use when your class is primarily a **data container** with no complex initialization logic. Add `frozen=True` for immutable objects with auto-generated `__hash__`. Add `order=True` for comparison operators. Use a regular class when you need complex init logic, class variables, or heavy method logic.

**Q7: Explain SOLID principles briefly.**
- **S**ingle Responsibility: One reason to change per class
- **O**pen/Closed: Open for extension, closed for modification (add subclasses, not `if isinstance`)
- **L**iskov Substitution: Subclass must be usable wherever parent is used
- **I**nterface Segregation: Many small interfaces — don't force clients to depend on unused methods
- **D**ependency Inversion: Depend on abstractions (ABCs/Protocols), not concrete classes

**Q8: What is `__slots__` and when would you use it?**
`__slots__ = ("x", "y")` prevents the creation of `__dict__` per instance — attributes are stored in a compact C array instead. Benefits: ~40–60% less memory per instance, slightly faster attribute access. Cost: can't add new attributes dynamically. Use when creating **millions of instances** (game entities, ML samples, network packets).

---

## Module Summary

| Concept | What it Does | When to Use |
|---------|-------------|-------------|
| `__init__` | Sets up instance state | Always, as the main constructor |
| `@property` | Adds validation/computation to attribute access | When attributes have constraints or are derived |
| `@classmethod` | Alternative constructor or factory method | `from_dict()`, `from_json()`, `from_file()` |
| `@staticmethod` | Utility tied to the class, needs no `self`/`cls` | Validators, formatters, pure functions |
| `@abstractmethod` | Enforces a contract on subclasses | Defining interfaces/protocols |
| Dunder methods | Protocol compliance (operators, len, iter) | When objects should behave like built-ins |
| `@dataclass` | Eliminates boilerplate for data containers | Value objects, DTOs, config classes |
| SOLID | Design guidelines for maintainability | Always — especially S, D |
| Repository | Decouples storage from business logic | Any system with persistence |
| Observer/Events | Decouples emitters from listeners | Notifications, analytics, real-time systems |

---

## Quiz

1. What is `self` really? How does Python pass it to methods?
2. What is the difference between `__str__` and `__repr__`? When is each called?
3. Why must `__eq__` return `NotImplemented` (not `False`) when types don't match?
4. What is the difference between `@classmethod` and `@staticmethod`? Give a use case for each.
5. Why can't you use a mutable default like `tags=[]` in a `@dataclass`?
6. What does `@dataclass(frozen=True)` do? Why does it generate `__hash__`?
7. What is name mangling? What does `self.__balance` become in memory?
8. Which SOLID principle does the Repository pattern primarily satisfy?
9. You have a `PaymentProcessor` class that directly instantiates `StripeClient`. Which SOLID principle does this violate? How do you fix it?
10. What is the MRO and why does Python use C3 linearisation instead of simple left-to-right?

**Answers:**
1. `self` is the instance object itself. Python finds the method on the class and automatically passes the instance as the first argument: `obj.method(x)` → `Class.method(obj, x)`.
2. `__repr__` is for developers (unambiguous, copy-pasteable). `__str__` is for users (readable). `repr()` falls back to `__repr__`; `str()` uses `__str__` if defined, else `__repr__`.
3. `NotImplemented` signals "I don't know how to compare these types — Python should try the other object's `__eq__`". `False` would incorrectly say they're definitely not equal.
4. `@classmethod` receives `cls` (the class itself) — use for alternative constructors like `from_dict()`. `@staticmethod` receives nothing — use for pure utility functions that logically belong to the class.
5. Mutable defaults are shared across all instances (same bug as mutable function default args). Use `field(default_factory=list)` instead.
6. `frozen=True` makes the dataclass immutable (like a `tuple`). Since values can't change, a consistent hash is guaranteed, so Python auto-generates `__hash__`.
7. `self.__balance` is stored as `self._ClassName__balance` in `__dict__`. This prevents accidental overriding in subclasses.
8. Single Responsibility (each class has one job) and Dependency Inversion (service depends on the abstract repository, not a concrete DB class).
9. Dependency Inversion Principle. Fix: define a `PaymentGateway` abstract class, inject an implementation into `PaymentProcessor`, swap `StripeClient` for `PayPalClient` without changing `PaymentProcessor`.
10. MRO determines which class's method to call in multiple inheritance. C3 linearisation ensures each class appears at most once and respects left-to-right declaration order, avoiding the "diamond problem" of ambiguous method resolution.
