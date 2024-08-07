## split_part

```text
split_part(source, separator, part)
```

Splits the `source` string into parts using the specified `separator` and returns the part indexed by `part`. Supports both positive and negative indexing for flexible retrieval.

```sql
SELECT split_part('https://www.googleapis.com/compute/v1/projects/testing-project/global/networks/default', '/', 1);
-- Returns 'https:'

SELECT split_part('https://www.googleapis.com/compute/v1/projects/testing-project/global/networks/default', '/', 3);
-- Returns 'compute'

SELECT split_part('https://www.googleapis.com/compute/v1/projects/testing-project/global/networks/default', '/', 8);
-- Returns 'networks'

SELECT split_part('https://www.googleapis.com/compute/v1/projects/testing-project/global/networks/default', '/', -1);
-- Returns 'default'

SELECT split_part('https://www.googleapis.com/compute/v1/projects/testing-project/global/networks/default', '/', -3);
-- Returns 'global'
```

### Parameters

- **source (string):** The input string to be split.
- **separator (string):** The character or string used to divide the source into parts.
- **part (integer):** The one-based index of the part to return. Supports negative indexing:
  - **Positive Index:** Counts from the start of the string, where 1 is the first part.
  - **Negative Index:** Counts backward from the end of the string, where -1 is the last part.

### Return Value

Returns the specified part of the source string if it exists; otherwise, returns `NULL`.

### Notes

- Consecutive separators will result in empty string parts being included.

### Installation and Usage

SQLite command-line interface:

```
sqlite> .load ./split_part.so
sqlite> SELECT split_part('example.com/path/to/resource', '/', 2);
```
### Implementation Details

This function is part of the StackQL extension suite for SQLite, providing enhanced string manipulation capabilities.

[⬇️ Download](https://github.com/stackql/stackql/releases/latest) •
[✨ Explore](https://github.com/stackql/stackql) •
[🚀 Follow](https://github.com/stackql)
