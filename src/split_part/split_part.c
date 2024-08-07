/*
** split_part(source, separator, part)
**
** This function splits a given string (`source`) into parts using a specified `separator`
** and returns the part indexed by `part`. The function supports both positive (one-based)
** and negative indexing, allowing flexible retrieval of string segments.
**
** Parameters:
** - source (string): The input string to be split.
** - separator (string): The character or string used to divide the source into parts.
** - part (integer): The one-based index of the part to return. Supports negative indexing:
**   - Positive Index: Counts from the start of the string, where 1 is the first part.
**   - Negative Index: Counts backward from the end of the string, where -1 is the last part.
**
** Returns:
** - The specified part of the source string if it exists; otherwise, NULL.
**
** Note:
** - Consecutive separators will result in empty string parts being included.
**
** Examples:
**   SELECT split_part('https://www.googleapis.com/compute/v1/projects/testing-project/global/networks/default', '/', 1);
**   -- Returns: 'https:'
**
**   SELECT split_part('https://www.googleapis.com/compute/v1/projects/testing-project/global/networks/default', '/', 3);
**   -- Returns: 'compute'
**
**   SELECT split_part('https://www.googleapis.com/compute/v1/projects/testing-project/global/networks/default', '/', 8);
**   -- Returns: 'networks'
**
**   SELECT split_part('https://www.googleapis.com/compute/v1/projects/testing-project/global/networks/default', '/', -1);
**   -- Returns: 'default'
**
**   SELECT split_part('https://www.googleapis.com/compute/v1/projects/testing-project/global/networks/default', '/', -3);
**   -- Returns: 'global'
**
** This function is part of the StackQL extension suite for SQLite, providing enhanced string manipulation capabilities.
*/

#include <sqlite3ext.h>
SQLITE_EXTENSION_INIT1

#include <string.h>
#include <stdlib.h>

#ifdef _WIN32
// Custom implementation of strndup for Windows
char* strndup(const char* s, size_t n) {
    size_t len = strlen(s);
    if (len > n) {
        len = n;
    }
    char* result = (char*)malloc(len + 1);
    if (!result) return NULL;
    result[len] = '\0';
    return (char*)memcpy(result, s, len);
}
#endif

// Helper function to split a string and return the specified part
static void split_part(sqlite3_context *context, int argc, sqlite3_value **argv) {
    if (argc != 3) {
        sqlite3_result_error(context, "split_part() requires exactly three arguments", -1);
        return;
    }

    const char *source = (const char *)sqlite3_value_text(argv[0]);
    const char *sep = (const char *)sqlite3_value_text(argv[1]);
    int part = sqlite3_value_int(argv[2]);

    if (source == NULL || sep == NULL || *sep == '\0') {
        sqlite3_result_null(context);
        return;
    }

    // Calculate separator length
    size_t sep_len = strlen(sep);

    // Create a mutable copy of the source string
    char *copy = strdup(source);
    if (!copy) {
        sqlite3_result_error_nomem(context);
        return;
    }

    // Initialize parts list
    char **parts = NULL;
    int count = 0;
    char *current = copy;
    char *next;

    // Parse the string
    while ((next = strstr(current, sep)) != NULL) {
        size_t token_len = next - current;

        // Allocate space for the new part
        char **temp = realloc(parts, sizeof(char*) * (count + 1));
        if (!temp) {
            sqlite3_result_error_nomem(context);
            free(copy);
            for (int i = 0; i < count; ++i) {
                free(parts[i]);
            }
            free(parts);
            return;
        }
        parts = temp;

        // Allocate and copy the token
        parts[count] = strndup(current, token_len);
        if (!parts[count]) {
            sqlite3_result_error_nomem(context);
            free(copy);
            for (int i = 0; i < count; ++i) {
                free(parts[i]);
            }
            free(parts);
            return;
        }
        count++;
        
        // Move past the separator
        current = next + sep_len;
    }

    // Handle the last part (after the last separator)
    char **temp = realloc(parts, sizeof(char*) * (count + 1));
    if (!temp) {
        sqlite3_result_error_nomem(context);
        free(copy);
        for (int i = 0; i < count; ++i) {
            free(parts[i]);
        }
        free(parts);
        return;
    }
    parts = temp;
    parts[count] = strdup(current);
    if (!parts[count]) {
        sqlite3_result_error_nomem(context);
        free(copy);
        for (int i = 0; i < count; ++i) {
            free(parts[i]);
        }
        free(parts);
        return;
    }
    count++;

    // Adjust the part index for one-based and negative indexing
    if (part < 0) {
        part = count + part;
    } else {
        part = part - 1;
    }

    // Return the requested part if it's in range
    if (part >= 0 && part < count) {
        sqlite3_result_text(context, parts[part], -1, SQLITE_TRANSIENT);
    } else {
        sqlite3_result_null(context);
    }

    // Free allocated memory
    for (int i = 0; i < count; ++i) {
        free(parts[i]);
    }
    free(parts);
    free(copy);
}

int sqlite3_splitpart_init(sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi) {
    SQLITE_EXTENSION_INIT2(pApi)
    int rc = SQLITE_OK;

    rc = sqlite3_create_function(db, "split_part", 3, SQLITE_UTF8, NULL, split_part, NULL, NULL);
    if (rc != SQLITE_OK) return rc;

    return rc;
}