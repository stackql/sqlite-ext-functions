## json_equal

```text
json_equal(JSON1, JSON2)
```

Compares two JSON strings and returns 1 if they are equivalent, 0 otherwise. This function supports comparison of JSON objects and arrays and treats objects with keys in different orders as equivalent, following the JSON specification.

```sql
SELECT json_equal('{"key": "value"}', '{"key": "value"}');
-- Returns 1 (true)

SELECT json_equal('{"key1": "value1", "key2": "value2"}', '{"key2": "value2", "key1": "value1"}');
-- Returns 1 (true)

SELECT json_equal('{"key": "value"}', '{"key": "different"}');
-- Returns 0 (false)

SELECT json_equal('[1, 2, 3]', '[1, 2, 3]');
-- Returns 1 (true)

SELECT json_equal('[1, 2, 3]', '[3, 2, 1]');
-- Returns 0 (false)

SELECT json_equal('[{"key": "value"}]', '[{"key": "value"}]');
-- Returns 1 (true)
```

### Key Features

- **Supports JSON objects and arrays:** Allows for deep comparisons of JSON structures.
- **Order-agnostic comparison:** Treats JSON objects with keys in different orders as equivalent, as per the JSON specification.

### Installation and Usage

SQLite command-line interface:

```
sqlite> .load ./json_equal.so
sqlite> SELECT json_equal('{"key": "value"}', '{"key": "value"}');
```
### Implementation Details

The `json_equal` function is implemented using the [cJSON library](https://github.com/DaveGamble/cJSON) by Dave Gamble. It is part of the StackQL extension suite for SQLite, providing enhanced JSON handling capabilities.

[⬇️ Download](https://github.com/stackql/stackql/releases/latest) •
[✨ Explore](https://github.com/stackql/stackql) •
[🚀 Follow](https://github.com/stackql)
