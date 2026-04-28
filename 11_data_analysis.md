# Module 11 — Data Analysis: NumPy and Pandas

> **Level:** Intermediate–Advanced | **Estimated Time:** 8 hours | **Prerequisites:** Modules 01–07

---

## Learning Objectives

By the end of this module you will be able to:
- Create and manipulate NumPy arrays efficiently
- Perform vectorised operations (no Python loops over arrays)
- Load, clean, and transform data with Pandas DataFrames
- Handle missing data, duplicates, and type inconsistencies
- Group, aggregate, merge, and reshape data
- Create exploratory visualisations with Matplotlib/Seaborn
- Build a complete data analysis pipeline

---

## The Big Picture — Why NumPy/Pandas in System Design and Interviews

```
Data Science and ML interview questions consistently test:
  - Vectorisation vs loops (NumPy) — can you eliminate Python-level iteration?
  - GroupBy + aggregation (Pandas) — can you answer analytical questions with 1-2 lines?
  - Memory efficiency — chunked reading, dtype optimization, generators
  - Data cleaning — handling missing values, type coercion, duplicates
  - Merge semantics — inner/left/right/outer joins and when each produces NaN

System Design applications:
  - Fraud detection: Pandas for feature engineering on transaction windows
  - ETL pipelines: chunked CSV reads, vectorised transforms, Parquet output
  - ML feature stores: NumPy arrays as the final format for model input
  - Analytics dashboards: Pandas groupby → aggregated JSON → API response

Key mindset: "If you're writing a for loop over a NumPy array or Pandas column,
you're almost always doing it wrong."
```

---

## 11.1 NumPy — Numerical Python

```bash
pip install numpy pandas matplotlib seaborn
```

### Conceptual Foundation

NumPy arrays store data in **contiguous memory blocks** and use **C-level loops** — up to 100× faster than Python lists for numerical operations. The key insight: avoid Python-level iteration over arrays; instead, use **vectorised operations** that apply to the entire array at once.

```python
import numpy as np

# Creating arrays
a1 = np.array([1, 2, 3, 4, 5])                       # 1D from list
a2 = np.array([[1, 2, 3], [4, 5, 6]])                 # 2D (matrix)
zeros = np.zeros((3, 4))                              # 3×4 matrix of zeros
ones = np.ones((2, 3), dtype=np.float32)              # with dtype
identity = np.eye(4)                                  # 4×4 identity matrix
rng = np.arange(0, 10, 0.5)                          # like range() but returns array
linspace = np.linspace(0, 1, 100)                    # 100 evenly spaced values

# Random arrays (reproducible with seed)
rng_gen = np.random.default_rng(seed=42)             # modern API
random_ints = rng_gen.integers(0, 100, size=(3, 4))  # 3×4 matrix of ints 0-99
random_norm = rng_gen.standard_normal((100,))         # standard normal samples

# Shape and dtype
print(a2.shape)    # (2, 3)
print(a2.ndim)     # 2
print(a2.size)     # 6 (total elements)
print(a2.dtype)    # int64
print(a2.nbytes)   # 48 (bytes used)
```

### Vectorised Operations

```python
a = np.array([1, 2, 3, 4, 5])
b = np.array([10, 20, 30, 40, 50])

# Element-wise arithmetic (no loops needed)
print(a + b)        # [11, 22, 33, 44, 55]
print(a * 2)        # [2, 4, 6, 8, 10]
print(b / a)        # [10., 10., 10., 10., 10.]
print(a ** 2)       # [1, 4, 9, 16, 25]
print(np.sqrt(a))   # [1., 1.414, 1.732, 2., 2.236]

# Universal functions (ufuncs) — vectorised math
x = np.linspace(0, 2 * np.pi, 100)
y = np.sin(x)       # sin applied to all 100 values at once
z = np.exp(-x)

# Broadcasting — smaller arrays are expanded to match larger shapes
matrix = np.ones((3, 4))     # shape (3, 4)
row = np.array([1, 2, 3, 4]) # shape (4,) → broadcast to (3, 4)
result = matrix + row
print(result)
# [[2. 3. 4. 5.]
#  [2. 3. 4. 5.]
#  [2. 3. 4. 5.]]

# Column broadcasting
col = np.array([[10], [20], [30]])  # shape (3, 1) → broadcast to (3, 4)
result2 = matrix + col
```

### Indexing and Slicing

```python
m = np.arange(1, 13).reshape(3, 4)
# [[ 1  2  3  4]
#  [ 5  6  7  8]
#  [ 9 10 11 12]]

print(m[0, 1])      # 2  (row 0, col 1)
print(m[1, :])      # [5 6 7 8]  (entire row 1)
print(m[:, 2])      # [3 7 11]   (entire col 2)
print(m[0:2, 1:3])  # [[2 3] [6 7]]  (submatrix)
print(m[-1])        # [9 10 11 12] (last row)

# Boolean indexing — the most powerful feature
data = np.array([3, -1, 7, -5, 2, -8, 4])
positive = data[data > 0]           # [3, 7, 2, 4]
data[data < 0] = 0                  # replace negatives with 0
print(data)                         # [3, 0, 7, 0, 2, 0, 4]

# Fancy indexing
indices = [0, 2, 4]
print(data[indices])                # [3, 7, 2]

# where — vectorised if/else
result = np.where(data > 3, data, -1)
# replace values ≤ 3 with -1
```

### Aggregations

```python
data = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])

print(data.sum())          # 45 (all elements)
print(data.sum(axis=0))    # [12, 15, 18] (sum each column)
print(data.sum(axis=1))    # [6, 15, 24]  (sum each row)
print(data.mean())         # 5.0
print(data.std())          # standard deviation
print(data.max())          # 9
print(data.argmax())       # 8 (flat index of maximum)
print(np.median(data))     # 5.0
print(np.percentile(data, [25, 50, 75]))  # quartiles
```

### Linear Algebra

```python
A = np.array([[1, 2], [3, 4]])
B = np.array([[5, 6], [7, 8]])

print(A @ B)            # matrix multiplication
print(np.dot(A, B))     # equivalent
print(A.T)              # transpose
print(np.linalg.det(A)) # determinant
print(np.linalg.inv(A)) # inverse
eigenvalues, eigenvectors = np.linalg.eig(A)
```

---

## 11.2 Pandas — Data Analysis

### Conceptual Foundation

Pandas provides two main structures:
- **Series** — 1D labeled array (like a column in a spreadsheet)
- **DataFrame** — 2D labeled table (like a spreadsheet or SQL table)

```python
import pandas as pd
import numpy as np

# --- Series ---
s = pd.Series([10, 20, 30, 40], index=["a", "b", "c", "d"])
print(s["b"])       # 20
print(s[s > 15])    # b    20, c    30, d    40
print(s.mean())     # 25.0

# --- DataFrame creation ---
# From dict
df = pd.DataFrame({
    "name":   ["Alice", "Bob", "Carol", "David", "Eve"],
    "age":    [30, 25, 35, 28, 32],
    "dept":   ["eng", "mkt", "eng", "hr", "eng"],
    "salary": [95000, 72000, 105000, 68000, 98000],
})

# From CSV
df = pd.read_csv("employees.csv", parse_dates=["hire_date"])

# From JSON
df = pd.read_json("data.json")

# From SQL
import sqlite3
conn = sqlite3.connect("mydb.sqlite")
df = pd.read_sql("SELECT * FROM employees", conn)
```

### Exploration

```python
print(df.shape)         # (5, 4) — rows, columns
print(df.dtypes)        # data type of each column
print(df.head())        # first 5 rows
print(df.tail(3))       # last 3 rows
print(df.info())        # summary: columns, dtypes, non-null counts, memory
print(df.describe())    # stats: count, mean, std, min, quartiles, max

# Column operations
print(df.columns.tolist())
print(df["name"])           # Series — single column
print(df[["name", "age"]]) # DataFrame — multiple columns

# Row selection
print(df.iloc[0])      # first row by integer position
print(df.iloc[1:3])    # rows 1, 2
print(df.loc[0])       # row by label (same as index here)
```

### Filtering and Selection

```python
# Boolean filtering
engineers = df[df["dept"] == "eng"]
high_earners = df[df["salary"] > 90000]
senior_engineers = df[(df["dept"] == "eng") & (df["age"] > 28)]

# query() — readable SQL-like syntax
result = df.query("dept == 'eng' and salary > 90000")

# isin() — membership filter
target_depts = ["eng", "hr"]
subset = df[df["dept"].isin(target_depts)]

# str methods — vectorised string operations
df["name_upper"] = df["name"].str.upper()
df["email_domain"] = df["email"].str.split("@").str[1]
contains_alice = df[df["name"].str.contains("alice", case=False)]
```

### Adding and Modifying Columns

```python
# Add new column
df["annual_bonus"] = df["salary"] * 0.10
df["is_senior"] = df["age"] >= 30
df["level"] = pd.cut(df["age"], bins=[0, 25, 30, 40, 100],
                     labels=["junior", "mid", "senior", "veteran"])

# Apply custom function
def classify_salary(salary: float) -> str:
    if salary >= 100000:
        return "high"
    elif salary >= 75000:
        return "medium"
    else:
        return "low"

df["salary_band"] = df["salary"].apply(classify_salary)

# Map values
dept_map = {"eng": "Engineering", "mkt": "Marketing", "hr": "Human Resources"}
df["department"] = df["dept"].map(dept_map)

# Rename columns
df = df.rename(columns={"dept": "department_code", "salary": "annual_salary"})
```

### Handling Missing Data

```python
# Detect missing values
print(df.isnull().sum())      # count NaN per column
print(df.isnull().any())      # True if any NaN in column
print(df.isnull().sum() / len(df) * 100)  # % missing

# Drop rows/columns with missing values
df_clean = df.dropna()                    # drop rows with ANY NaN
df_clean = df.dropna(subset=["salary"])   # drop only if salary is NaN
df_clean = df.dropna(thresh=3)            # keep rows with ≥ 3 non-NaN values

# Fill missing values
df["age"].fillna(df["age"].median(), inplace=True)    # fill with median
df["dept"].fillna("unknown", inplace=True)             # fill with string
df["salary"].fillna(method="ffill", inplace=True)      # forward fill

# Interpolation
df["price"].interpolate(method="linear", inplace=True)

# Replace specific values
df["dept"].replace({"eng": "engineering", "mkt": "marketing"}, inplace=True)
```

### Groupby — Split-Apply-Combine

```python
# GROUP BY dept — SQL equivalent: SELECT dept, AVG(salary) FROM df GROUP BY dept
summary = df.groupby("dept")["salary"].mean()
print(summary)

# Multiple aggregations
agg = df.groupby("dept").agg(
    headcount=("name", "count"),
    avg_salary=("salary", "mean"),
    max_salary=("salary", "max"),
    avg_age=("age", "mean"),
)
print(agg)

# groupby with multiple columns
pivot = df.groupby(["dept", "is_senior"])["salary"].mean().unstack()

# Apply a custom aggregation
def salary_range(series):
    return series.max() - series.min()

df.groupby("dept")["salary"].apply(salary_range)
```

### Merging and Joining

```python
# SQL-style joins
employees = pd.DataFrame({
    "emp_id": [1, 2, 3, 4],
    "name": ["Alice", "Bob", "Carol", "David"],
    "dept_id": [10, 20, 10, 30],
})
departments = pd.DataFrame({
    "dept_id": [10, 20, 40],
    "dept_name": ["Engineering", "Marketing", "Finance"],
})

# Inner join — only matching rows
inner = pd.merge(employees, departments, on="dept_id", how="inner")

# Left join — all employees, NaN for missing dept
left = pd.merge(employees, departments, on="dept_id", how="left")

# Concatenate DataFrames vertically (stack)
q1_sales = pd.DataFrame({"month": ["Jan", "Feb", "Mar"], "revenue": [100, 120, 95]})
q2_sales = pd.DataFrame({"month": ["Apr", "May", "Jun"], "revenue": [110, 130, 105]})
full_year = pd.concat([q1_sales, q2_sales], ignore_index=True)
```

### Pivot Tables and Reshaping

```python
# Pivot table
pivot = df.pivot_table(
    values="salary",
    index="dept",
    columns="is_senior",
    aggfunc=["mean", "count"],
)

# Melt — wide to long format (good for visualisation)
wide = pd.DataFrame({
    "name": ["Alice", "Bob"],
    "q1_sales": [100, 120],
    "q2_sales": [95, 130],
})
long = pd.melt(wide, id_vars=["name"], var_name="quarter", value_name="sales")
# name   quarter  sales
# Alice  q1_sales   100
# Alice  q2_sales    95
```

---

## 11.3 Exploratory Data Analysis Pipeline

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

def eda_pipeline(df: pd.DataFrame, target_col: str) -> None:
    """
    Run a standard exploratory data analysis on a DataFrame.
    Prints summary stats and generates key plots.
    """
    print("=" * 60)
    print("EXPLORATORY DATA ANALYSIS")
    print("=" * 60)

    print(f"\nShape: {df.shape[0]:,} rows × {df.shape[1]} columns\n")

    # Missing values
    missing = df.isnull().sum()
    if missing.any():
        print("Missing Values:")
        print(missing[missing > 0].to_string())
        print()

    # Numeric summary
    print("Numeric Summary:")
    print(df.describe(include="number").round(2).to_string())

    # Categorical summary
    cat_cols = df.select_dtypes(include="object").columns.tolist()
    for col in cat_cols:
        print(f"\n{col} value counts:")
        print(df[col].value_counts().head(10).to_string())

    # Correlation heatmap
    numeric_df = df.select_dtypes(include="number")
    if len(numeric_df.columns) > 1:
        fig, axes = plt.subplots(1, 2, figsize=(14, 5))

        # Correlation matrix
        corr = numeric_df.corr()
        sns.heatmap(corr, annot=True, fmt=".2f", cmap="coolwarm", ax=axes[0])
        axes[0].set_title("Correlation Matrix")

        # Target distribution
        if target_col in numeric_df.columns:
            axes[1].hist(df[target_col], bins=30, edgecolor="black")
            axes[1].set_xlabel(target_col)
            axes[1].set_ylabel("Frequency")
            axes[1].set_title(f"Distribution of {target_col}")

        plt.tight_layout()
        plt.savefig("eda_plots.png", dpi=150, bbox_inches="tight")
        plt.show()
```

---

## 11.4 Performance Tips for Large Datasets

```python
# Use appropriate dtypes — saves memory
df["category"] = df["category"].astype("category")  # for low-cardinality strings
df["age"] = df["age"].astype("int32")                # 4 bytes vs 8

# Read only needed columns from CSV
df = pd.read_csv("large.csv", usecols=["name", "salary", "dept"])

# Read in chunks — process datasets larger than RAM
chunk_results = []
for chunk in pd.read_csv("huge_file.csv", chunksize=100_000):
    result = chunk[chunk["salary"] > 80000]["salary"].sum()
    chunk_results.append(result)
total = sum(chunk_results)

# Use query() — often faster for complex boolean filters
result = df.query("age > 28 and salary > 90000 and dept == 'eng'")

# Vectorised string operations — always faster than .apply(lambda)
# BAD:
df["upper"] = df["name"].apply(lambda x: x.upper())
# GOOD:
df["upper"] = df["name"].str.upper()
```

---

## Exercises

### Exercise 11.1 — Sales Data Analysis
Given a CSV with columns `date`, `product`, `category`, `quantity`, `unit_price`:
1. Calculate total revenue per category
2. Find the top 3 products by revenue
3. Calculate monthly revenue trend
4. Find products with declining sales (month-over-month drop > 20%)

**Solution:**
```python
import pandas as pd

def analyse_sales(filepath: str) -> dict:
    """Comprehensive sales data analysis pipeline."""
    df = pd.read_csv(filepath, parse_dates=["date"])
    df["revenue"] = df["quantity"] * df["unit_price"]
    df["month"] = df["date"].dt.to_period("M")

    return {
        "revenue_by_category": df.groupby("category")["revenue"].sum().sort_values(ascending=False),
        "top_products": df.groupby("product")["revenue"].sum().nlargest(3),
        "monthly_trend": df.groupby("month")["revenue"].sum(),
    }
```

---

### Exercise 11.2 — Data Cleaning Pipeline
Clean a messy dataset with: mixed case column names, extra spaces in strings, mixed date formats, outliers (salary > 1M or < 0), and duplicate rows.

**Solution:**
```python
def clean_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    """Standard data cleaning pipeline."""
    # Standardise column names
    df.columns = df.columns.str.strip().str.lower().str.replace(" ", "_")

    # Strip whitespace from string columns
    str_cols = df.select_dtypes(include="object").columns
    df[str_cols] = df[str_cols].apply(lambda col: col.str.strip())

    # Remove duplicates
    df = df.drop_duplicates()

    # Remove salary outliers
    if "salary" in df.columns:
        df = df[(df["salary"] >= 0) & (df["salary"] <= 1_000_000)]

    # Reset index after filtering
    return df.reset_index(drop=True)
```

---

## Mini-Project — Employee Analytics Dashboard

```python
import pandas as pd
import numpy as np

def generate_employee_report(filepath: str) -> None:
    """Full employee analytics report from CSV data."""
    df = pd.read_csv(filepath, parse_dates=["hire_date"])
    df["years_tenure"] = (pd.Timestamp.now() - df["hire_date"]).dt.days / 365.25
    df["salary_band"] = pd.cut(
        df["salary"],
        bins=[0, 60000, 80000, 100000, float("inf")],
        labels=["<60k", "60-80k", "80-100k", ">100k"]
    )

    print("=" * 60)
    print("EMPLOYEE ANALYTICS REPORT")
    print("=" * 60)

    # Headcount and payroll by department
    dept_stats = df.groupby("department").agg(
        headcount=("emp_id", "count"),
        total_payroll=("salary", "sum"),
        avg_salary=("salary", "mean"),
        avg_tenure=("years_tenure", "mean"),
    ).round(2)
    print("\nDepartment Summary:\n", dept_stats.to_string())

    # Salary distribution
    print("\nSalary Band Distribution:")
    print(df["salary_band"].value_counts().sort_index().to_string())

    # Top earners
    print("\nTop 5 Earners:")
    top5 = df.nlargest(5, "salary")[["name", "department", "salary"]]
    print(top5.to_string(index=False))

    # Turnover risk — low tenure, high salary mismatch
    risk = df[
        (df["years_tenure"] < 1.5) &
        (df["salary"] < df.groupby("department")["salary"].transform("mean"))
    ][["name", "department", "salary", "years_tenure"]]
    print(f"\nRetention Risk Employees ({len(risk)}):")
    if not risk.empty:
        print(risk.to_string(index=False))
```

---

## Interview Prep — Top Questions for Data Analysis

**Q1: Why is vectorisation critical in NumPy, and how do you identify non-vectorised code?**
Vectorised operations apply C-level loops to entire arrays without Python object overhead (no per-element type checking, reference counting, or function dispatch). Non-vectorised code uses `for` loops over arrays or `.apply()` over DataFrames. Identify with `cProfile` or by looking for Python-level iteration over NumPy/Pandas objects. Rule: if you see `for item in array`, ask "can I express this as `array[mask]`, `np.where()`, or a vectorised Pandas method?"

**Q2: Explain the difference between `df.loc`, `df.iloc`, and `df.at`.**
- `df.loc[row_label, col_label]`: label-based; accepts boolean arrays, slices, lists of labels
- `df.iloc[row_int, col_int]`: integer-position-based; always 0-indexed like Python lists  
- `df.at[row_label, col_label]`: label-based single-value access (faster than `loc` for a single cell)
- `df.iat[row_int, col_int]`: integer-position single-value access (fastest for scalar reads)

**Q3: What is broadcasting in NumPy? When does it fail?**
Broadcasting allows NumPy to operate on arrays with different shapes by expanding dimensions of size 1. Rules: align shapes from the right; dimensions must match or be 1. `(4,3) + (3,)` → broadcasts `(3,)` to `(4,3)`. `(4,3) + (4,)` fails because `4 ≠ 3` (after right-aligning). Always check `array.shape` when debugging broadcasting errors.

**Q4: How do you handle missing data in a Pandas DataFrame?**
- `df.isnull().sum()` — count NaNs per column
- `df.dropna(subset=["col"])` — drop rows with NaN in specific columns
- `df.fillna(0)` or `df.fillna(method="ffill")` — fill with value or forward-fill
- `df["col"].interpolate()` — linear interpolation for time series
Key question: WHY is data missing? MCAR (random) vs MAR (systematic) vs MNAR determines the right strategy.

**Q5: What is the difference between `merge`, `join`, and `concat`?**
- `pd.merge(left, right, on="key", how="inner")`: SQL-style join on column(s), full control
- `df.join(other, how="left")`: join on index (or column) — shorthand for merge on index
- `pd.concat([df1, df2], axis=0)`: stack DataFrames vertically (more rows) or horizontally (more cols)
Use `merge` for most relational operations; `concat` for stacking similar-structured data.

**Q6: How would you process a 10GB CSV file that doesn't fit in RAM?**
Use `pd.read_csv(path, chunksize=100_000)` to iterate in chunks. Process each chunk (filter, aggregate, transform) and accumulate only summary results. Alternatively: convert to Parquet format (columnar, compressed, supports predicate pushdown) and use `pyarrow` or `dask` for out-of-core processing. For distributed scale, use PySpark or Dask.

**Q7: Explain the difference between `groupby().agg()` and `groupby().transform()`.**
- `.agg()` returns one row per group (reduced shape) — use for summaries
- `.transform()` returns the same shape as the input — each row gets the group's aggregate value (useful for adding group statistics back to original rows: `df["group_mean"] = df.groupby("dept")["salary"].transform("mean")`)

---

## Module Summary

| Concept | Key Takeaway |
|---------|-------------|
| NumPy arrays | Contiguous C arrays; vectorised ops are 10–100× faster than loops |
| Broadcasting | Smaller arrays expand to match larger shapes automatically |
| Boolean indexing | `arr[arr > 0]` — most powerful selection technique |
| Pandas Series | 1D labeled array with index |
| Pandas DataFrame | 2D labeled table — the workhorse of data analysis |
| `groupby()` | Split-Apply-Combine for aggregations |
| `merge()` | SQL-style joins between DataFrames |
| `astype("category")` | Efficient string storage for low-cardinality columns |

---

## Quiz

1. Why is NumPy array arithmetic faster than a Python loop?
2. What is broadcasting and when does it fail?
3. What is the difference between `df.loc` and `df.iloc`?
4. How does `df.groupby().agg()` work? Give an example.
5. What does `df.merge(other, how="left")` return?
6. What is the difference between `dropna()` and `fillna()`?
7. Why should you use `str.upper()` instead of `apply(lambda x: x.upper())`?
8. What does `pd.cut()` do and when would you use it?
9. How do you read a CSV file with 10 million rows without running out of RAM?
10. What does `df.pivot_table(values="sales", index="region", columns="year", aggfunc="sum")` produce?

**Answers:**
1. NumPy arrays are stored in **contiguous C memory** (not Python objects). Operations call compiled C/Fortran loops under the hood — no Python object creation, reference counting, or type dispatch per element. A Python loop does all of these for every element, making it 10–100× slower for numerical work.
2. Broadcasting lets NumPy perform operations on arrays with different shapes by automatically expanding smaller arrays. It fails (raises `ValueError`) when dimensions are incompatible: shapes must either match exactly, or one of them must be 1. E.g., `(3,4) + (3,)` fails; `(3,4) + (3,1)` succeeds (broadcast column-wise).
3. `df.loc[row_label, col_label]` selects by **index label** (string/date/custom). `df.iloc[row_int, col_int]` selects by **integer position** (0-based, like list indexing). Use `loc` when your index has meaningful labels; `iloc` for positional slicing.
4. `groupby("col")` splits the DataFrame into groups. `.agg({"salary": "mean", "age": "max"})` applies the specified aggregation function to each group. Returns a new DataFrame indexed by the group key. Example: `df.groupby("dept").agg({"salary": "mean"})` gives average salary per department.
5. A left join keeps all rows from the left DataFrame. Matching rows from `other` are added; where there's no match, the columns from `other` are filled with `NaN`. The result always has the same number of rows as the left DataFrame (or more, if there are one-to-many matches).
6. `dropna()` **removes** rows (or columns) that contain any `NaN`. `fillna(value)` **replaces** `NaN` with a specified value (scalar, forward-fill `method="ffill"`, or backward-fill). Use `dropna` when missing rows are unusable; `fillna` when you have a sensible imputation strategy.
7. `df["col"].str.upper()` is a **vectorised Pandas string method** — executed in compiled code. `apply(lambda x: x.upper())` runs a Python-level loop, calling a lambda for every row. The `str` accessor is typically 3–10× faster and more readable.
8. `pd.cut(df["age"], bins=[0,18,35,60,100], labels=["teen","young","mid","senior"])` bins a continuous numeric column into discrete categorical intervals. Use it for age groups, price tiers, score bands — any time you want to discretize a continuous variable for analysis or ML features.
9. Use `pd.read_csv(path, chunksize=100_000)` which returns an iterator of DataFrames. Process each chunk independently and aggregate results. This keeps at most one chunk in RAM at a time instead of loading all 10M rows. Alternatively, use Parquet format with `pyarrow` for columnar reads.
10. A 2D summary table with **regions as rows**, **years as columns**, and **sum of sales as cell values**. It's the Pandas equivalent of an Excel pivot table — useful for cross-tabulated reports and cohort analysis.
