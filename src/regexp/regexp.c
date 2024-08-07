/*
** SQLite extensions for working with regular expressions using https://github.com/kokke/tiny-regex-c.
**
** This extension provides functions for pattern matching and manipulation of strings
** using regular expressions. It is built using the tiny-regex-c library by Kristian Evensen,
** which offers a minimalistic and efficient implementation of regular expressions in C.
**
** Provided Functions:
** - regexp_like(source, pattern)
**   - Checks if the source string matches the pattern.
**
** - regexp_substr(source, pattern)
**   - Returns the substring of the source that matches the pattern.
**
** - regexp_replace(source, pattern, replacement)
**   - Replaces the matching substring with the replacement string.
**
** Supported Regular Expression Syntax:
**   - X*      Zero or more occurrences of X
**   - X+      One or more occurrences of X
**   - X?      Zero or one occurrences of X
**   - (X)     Match X
**   - X|Y     X or Y
**   - ^X      X occurring at the beginning of the string
**   - X$      X occurring at the end of the string
**   - .       Match any single character
**   - \c      Character c where c is one of \{}()[]|*+?.
**   - \c      C-language escapes for c in afnrtv, e.g., \t or \n
**   - [abc]   Any single character from the set abc
**   - [^abc]  Any single character not in the set abc
**   - [a-z]   Any single character in the range a-z
**   - [^a-z]  Any single character not in the range a-z
**
** This extension is part of the StackQL suite for SQLite, offering enhanced string manipulation capabilities.
*/

#include <sqlite3ext.h>
SQLITE_EXTENSION_INIT1

#include "re.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>  // For snprintf

static void regexp_like(sqlite3_context *context, int argc, sqlite3_value **argv) {
    if (argc != 2) {
        sqlite3_result_error(context, "regexp_like() requires exactly two arguments", -1);
        return;
    }

    const char *str = (const char *)sqlite3_value_text(argv[0]);
    const char *pattern = (const char *)sqlite3_value_text(argv[1]);

    if (str == NULL || pattern == NULL) {
        sqlite3_result_null(context);
        return;
    }

    re_t regex = re_compile(pattern);
    if (regex == NULL) {
        sqlite3_result_error(context, "Invalid regular expression", -1);
        return;
    }

    int match_len;
    int match = re_matchp(regex, str, &match_len);
    sqlite3_result_int(context, match != -1);  // Return 1 if match, 0 if not
}

static void regexp_replace(sqlite3_context *context, int argc, sqlite3_value **argv) {
    if (argc != 3) {
        sqlite3_result_error(context, "regexp_replace() requires exactly three arguments", -1);
        return;
    }

    const char *str = (const char *)sqlite3_value_text(argv[0]);
    const char *pattern = (const char *)sqlite3_value_text(argv[1]);
    const char *replacement = (const char *)sqlite3_value_text(argv[2]);

    if (str == NULL || pattern == NULL || replacement == NULL) {
        sqlite3_result_null(context);
        return;
    }

    re_t regex = re_compile(pattern);
    if (regex == NULL) {
        sqlite3_result_error(context, "Invalid regular expression", -1);
        return;
    }

    char *result = NULL;
    size_t len = 0;
    const char *cursor = str;
    int match_len;
    int match_start;

    while ((match_start = re_matchp(regex, cursor, &match_len)) != -1) {
        size_t prefix_len = match_start;
        size_t suffix_len = strlen(cursor + match_start + match_len);
        size_t rep_len = strlen(replacement);

        char *temp = realloc(result, len + prefix_len + rep_len + suffix_len + 1);
        if (!temp) {
            sqlite3_result_error_nomem(context);
            free(result);
            return;
        }

        result = temp;
        memcpy(result + len, cursor, prefix_len);
        len += prefix_len;
        memcpy(result + len, replacement, rep_len);
        len += rep_len;
        cursor += match_start + match_len;
    }

    if (result) {
        strcpy(result + len, cursor);
        sqlite3_result_text(context, result, -1, free);
    } else {
        sqlite3_result_text(context, str, -1, SQLITE_TRANSIENT);
    }
}

static void regexp_substr(sqlite3_context *context, int argc, sqlite3_value **argv) {
    if (argc != 2) {
        sqlite3_result_error(context, "regexp_substr() requires exactly two arguments", -1);
        return;
    }

    const char *str = (const char *)sqlite3_value_text(argv[0]);
    const char *pattern = (const char *)sqlite3_value_text(argv[1]);

    if (str == NULL || pattern == NULL) {
        sqlite3_result_null(context);
        return;
    }

    re_t regex = re_compile(pattern);
    if (regex == NULL) {
        sqlite3_result_error(context, "Invalid regular expression", -1);
        return;
    }

    int match_len;
    int match_start = re_matchp(regex, str, &match_len);
    if (match_start != -1) {
        char *match_str = (char *)malloc(match_len + 1);
        if (!match_str) {
            sqlite3_result_error_nomem(context);
            return;
        }

        strncpy(match_str, str + match_start, match_len);
        match_str[match_len] = '\0';
        sqlite3_result_text(context, match_str, -1, free);
    } else {
        sqlite3_result_null(context);
    }
}

int sqlite3_regexp_init(sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi) {
    SQLITE_EXTENSION_INIT2(pApi)
    int rc = SQLITE_OK;

    rc = sqlite3_create_function(db, "regexp_like", 2, SQLITE_UTF8, NULL, regexp_like, NULL, NULL);
    if (rc != SQLITE_OK) return rc;

    rc = sqlite3_create_function(db, "regexp_replace", 3, SQLITE_UTF8, NULL, regexp_replace, NULL, NULL);
    if (rc != SQLITE_OK) return rc;

    rc = sqlite3_create_function(db, "regexp_substr", 2, SQLITE_UTF8, NULL, regexp_substr, NULL, NULL);
    return rc;
}