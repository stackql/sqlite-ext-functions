## Regular Expression Functions in SQLite

These functions provide capabilities for regular expression pattern matching and string manipulation. Each function expects the input `source` and `pattern` to be TEXT. They offer features like checking for matches, extracting substrings, and replacing patterns.

[regexp_like](#regexp_like) •
[regexp_substr](#regexp_substr) •
[regexp_replace](#regexp_replace)

### regexp_like

```text
regexp_like(source, pattern)
```

Checks if the `source` string matches the `pattern`. Returns 1 if the pattern matches the string, 0 otherwise.

```sql
SELECT regexp_like('hello world', 'hello');
-- Returns 1

SELECT regexp_like('hello world', '^world');
-- Returns 0
```

### regexp_substr

```text
regexp_substr(source, pattern)
```

Returns the substring of the `source` that matches the `pattern`. If no match is found, it returns `NULL`.

```sql
SELECT regexp_substr('hello world', 'w.*d');
-- Returns 'world'

SELECT regexp_substr('hello world', 'abc');
-- Returns NULL
```

### regexp_replace

```text
regexp_replace(source, pattern, replacement)
```

Replaces the substring of the `source` that matches the `pattern` with the `replacement` string. If no match is found, the original string is returned.

```sql
SELECT regexp_replace('hello world', 'world', 'SQLite');
-- Returns 'hello SQLite'

SELECT regexp_replace('hello world', 'abc', 'def');
-- Returns 'hello world'
```

### Supported Regular Expression Syntax

- **X\***      Zero or more occurrences of X
- **X\+**      One or more occurrences of X
- **X?**       Zero or one occurrence of X
- **(X)**      Match X
- **X\|Y**     X or Y
- **^X**       X occurring at the beginning of the string
- **X$**       X occurring at the end of the string
- **.**        Match any single character
- **\\c**      Character c where c is one of \\\{}()[]\|*+?.
- **\\c**      C-language escapes for c in afnrtv, e.g., \t or \n
- **[abc]**    Any single character from the set abc
- **[^abc]**   Any single character not in the set abc
- **[a-z]**    Any single character in the range a-z
- **[^a-z]**   Any single character not in the range a-z

### Installation and Usage

SQLite command-line interface:

```
sqlite> .load ./regexp_fns.so
sqlite> SELECT regexp_like('hello world', 'hello');
```

### Implementation Details

This extension is built using the [tiny-regex-c library](https://github.com/kokke/tiny-regex-c) by Kristian Evensen, providing a minimalistic and efficient implementation of regular expressions in C. It is part of the StackQL suite for SQLite, offering enhanced string manipulation capabilities.

[⬇️ Download](https://github.com/stackql/stackql/releases/latest) •
[✨ Explore](https://github.com/stackql/stackql) •
[🚀 Follow](https://github.com/stackql)
