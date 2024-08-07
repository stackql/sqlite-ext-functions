# SQLite Extended Functions for StackQL

Extended SQLite functions for StackQL providing additional capabilities for JSON manipulation, regular expressions, and string splitting.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Development](#development)
- [License](#license)

## Introduction

This repository contains a set of extended functions for SQLite designed to enhance the SQL capabilities in StackQL. These extensions provide additional JSON handling, regular expression matching, and string manipulation functionalities.

## Features

- **JSON Functions**: Includes `json_equal` to compare JSON objects and arrays.
- **Regular Expression Functions**: Includes `regexp_like`, `regexp_substr`, and `regexp_replace` for pattern matching and manipulation.
- **String Splitting Function**: Includes `split_part` to split strings based on a separator and retrieve specific parts.

## Installation

### Prerequisites

- **SQLite**: Ensure SQLite is installed on your system.
- **GCC**: Required for compiling the extensions.
- **Git**: For cloning the repository.

### Building from Source

Clone the repository and build the extensions:

```bash
git clone https://github.com/stackql/sqlite-ext-functions.git
cd sqlite-ext-functions

# Prepare the distribution directory
make prepare-dist

# Download the SQLite amalgamation source
make download-sqlite

# Compile the extensions for your platform
make compile-linux    # For Linux
make compile-windows  # For Windows
make compile-macos    # For macOS
```

### Load Extensions

After compilation, you can load the extensions in your SQLite shell using:

```sql
.load '/path/to/dist/json_equal'
.load '/path/to/dist/regexp'
.load '/path/to/dist/split_part'
```

## Usage

### JSON Functions

```sql
SELECT json_equal('{"key": "value"}', '{"key": "value"}'); -- Returns 1 (true)
SELECT json_equal('[1, 2, 3]', '[3, 2, 1]'); -- Returns 0 (false)
```

### Regular Expression Functions

```sql
SELECT regexp_like('hello world', '^hello'); -- Returns 1 (true)
SELECT regexp_substr('hello world', 'w.*d'); -- Returns 'world'
SELECT regexp_replace('hello world', 'world', 'SQLite'); -- Returns 'hello SQLite'
```

### String Splitting Function

```sql
SELECT split_part('one,two,three', ',', 2); -- Returns 'two'
SELECT split_part('one,two,three', ',', -1); -- Returns 'three'
```

## Development

### Testing

Run tests to verify the functionality of the extensions:

```bash
make test-all
```

### Clean Up

Clean the distribution directory and test logs:

```bash
make clean
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For questions or support, please reach out to [StackQL Studios](https://github.com/stackql).

