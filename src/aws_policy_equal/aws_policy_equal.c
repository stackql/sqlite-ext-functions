/*
** aws_policy_equal(POLICY1, POLICY2)
**
** This function compares two AWS IAM policy JSON strings and returns true if they are semantically equivalent
** according to AWS IAM policy evaluation rules, false otherwise.
**
** Key Features:
** - Supports comparison of AWS IAM policy documents
** - Treats arrays in certain contexts (Principal, Action, Resource, etc.) as unordered sets
** - Handles case-insensitive service names in ARNs
** - Normalized comparison of AWS policy elements according to AWS evaluation logic
**
** Usage Examples:
**   // Policy comparisons:
**   SELECT aws_policy_equal(
**     '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}',
**     '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"s3:*","Resource":"*"}]}'
**   ); -- Returns 1 (true)
**
**   // Order-insensitive comparisons:
**   SELECT aws_policy_equal(
**     '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":["arn1","arn2"]}}]}',
**     '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":["arn2","arn1"]}}]}'
**   ); -- Returns 1 (true)
**
** This function is part of the StackQL extension suite for SQLite, providing AWS policy comparison capabilities.
*/

#include <sqlite3ext.h>
SQLITE_EXTENSION_INIT1

#include "cJSON.h"
#include <string.h>
#include <ctype.h>

// List of fields that should be compared as unordered sets
static const char *unordered_arrays[] = {
    "Action", "NotAction", "Resource", "NotResource", "Principal", "NotPrincipal", "AWS", "Service"
};

// Count of unordered array fields
#define UNORDERED_ARRAYS_COUNT (sizeof(unordered_arrays) / sizeof(unordered_arrays[0]))

// Check if a field name is in the list of unordered arrays
static int is_unordered_array(const char *field_name) {
    for (int i = 0; i < UNORDERED_ARRAYS_COUNT; i++) {
        if (strcmp(field_name, unordered_arrays[i]) == 0) {
            return 1;
        }
    }
    return 0;
}

// Case-insensitive string comparison for service names in ARNs
static int aws_service_compare(const char *str1, const char *str2) {
    if (str1 == NULL || str2 == NULL) {
        return str1 == str2;
    }
    
    while (*str1 && *str2) {
        char c1 = tolower((unsigned char)*str1);
        char c2 = tolower((unsigned char)*str2);
        if (c1 != c2) {
            return 0;
        }
        str1++;
        str2++;
    }
    
    return *str1 == *str2;
}

// Find an element in an array by value (for unordered comparison)
static cJSON *find_matching_element(cJSON *array, cJSON *item, int parent_is_unordered) {
    cJSON *element;
    
    // Nothing to find in empty arrays
    if (array == NULL || item == NULL) {
        return NULL;
    }
    
    // Check each element in the array
    cJSON_ArrayForEach(element, array) {
        // For unordered arrays, use our specialized comparison
        if (aws_policy_compare_items(element, item, parent_is_unordered)) {
            return element;
        }
    }
    
    return NULL;
}

// Specialized comparison for AWS policy JSON elements
static cJSON_bool aws_policy_compare_items(const cJSON *a, const cJSON *b, int parent_is_unordered) {
    // If items are the same pointer, they're equal
    if (a == b) {
        return 1;
    }
    
    // If either is NULL or they have different types, they're not equal
    if ((a == NULL) || (b == NULL) || ((a->type & 0xFF) != (b->type & 0xFF))) {
        return 0;
    }
    
    // Based on the item type, do specific comparisons
    switch (a->type & 0xFF) {
        // For simple types, use standard comparison
        case cJSON_False:
        case cJSON_True:
        case cJSON_NULL:
            return 1;
            
        case cJSON_Number:
            return compare_double(a->valuedouble, b->valuedouble);
            
        case cJSON_String:
        case cJSON_Raw:
            if ((a->valuestring == NULL) || (b->valuestring == NULL)) {
                return 0;
            }
            
            // For service names or ARNs, do case-insensitive comparison
            if (parent_is_unordered && (strstr(a->valuestring, "arn:") == a->valuestring)) {
                return aws_service_compare(a->valuestring, b->valuestring);
            } else {
                return strcmp(a->valuestring, b->valuestring) == 0;
            }
            
        case cJSON_Array:
            {
                cJSON *a_element = NULL;
                cJSON *b_element = NULL;
                int element_count = 0;
                int matched_elements = 0;
                int is_unordered = parent_is_unordered;
                
                // Count the elements in array a
                cJSON_ArrayForEach(a_element, a) {
                    element_count++;
                }
                
                // Check if arrays have the same number of elements
                if (element_count != cJSON_GetArraySize(b)) {
                    return 0;
                }
                
                // If this is an unordered array, each element in A must exist in B
                if (is_unordered) {
                    cJSON_ArrayForEach(a_element, a) {
                        b_element = find_matching_element(b, a_element, is_unordered);
                        if (b_element != NULL) {
                            matched_elements++;
                        } else {
                            return 0;
                        }
                    }
                    return matched_elements == element_count;
                } else {
                    // For ordered arrays, compare elements in order
                    a_element = a->child;
                    b_element = b->child;
                    
                    while (a_element != NULL && b_element != NULL) {
                        if (!aws_policy_compare_items(a_element, b_element, is_unordered)) {
                            return 0;
                        }
                        a_element = a_element->next;
                        b_element = b_element->next;
                    }
                    
                    // If we reached the end of both arrays, they're equal
                    return (a_element == NULL && b_element == NULL);
                }
            }
            
        case cJSON_Object:
            {
                cJSON *a_element = NULL;
                cJSON *b_element = NULL;
                
                // Each property in A must exist in B with equivalent value
                cJSON_ArrayForEach(a_element, a) {
                    // Check if we should treat arrays in this field as unordered
                    int field_is_unordered = is_unordered_array(a_element->string);
                    
                    // Get matching property from B
                    b_element = cJSON_GetObjectItem(b, a_element->string);
                    
                    // If property doesn't exist or values don't match, objects aren't equal
                    if ((b_element == NULL) || !aws_policy_compare_items(a_element, b_element, field_is_unordered)) {
                        return 0;
                    }
                }
                
                // Each property in B must exist in A
                cJSON_ArrayForEach(b_element, b) {
                    a_element = cJSON_GetObjectItem(a, b_element->string);
                    if (a_element == NULL) {
                        return 0;
                    }
                }
                
                return 1;
            }
            
        default:
            return 0;
    }
}

// Forward declaration
static cJSON_bool aws_policy_compare_items(const cJSON *a, const cJSON *b, int parent_is_unordered);

static void aws_policy_equal(sqlite3_context *context, int argc, sqlite3_value **argv) {
    if (argc != 2) {
        sqlite3_result_error(context, "aws_policy_equal() requires exactly two arguments", -1);
        return;
    }

    const char *policy1 = (const char *)sqlite3_value_text(argv[0]);
    const char *policy2 = (const char *)sqlite3_value_text(argv[1]);

    if (policy1 == NULL || policy2 == NULL) {
        sqlite3_result_error(context, "Invalid policy strings", -1);
        return;
    }

    // If the strings are identical, they're equal (shortcut)
    if (strcmp(policy1, policy2) == 0) {
        sqlite3_result_int(context, 1);
        return;
    }

    cJSON *policy_obj1 = cJSON_Parse(policy1);
    cJSON *policy_obj2 = cJSON_Parse(policy2);

    if (policy_obj1 == NULL || policy_obj2 == NULL) {
        sqlite3_result_error(context, "Error parsing policy JSON strings", -1);
        cJSON_Delete(policy_obj1);
        cJSON_Delete(policy_obj2);
        return;
    }

    // Compare the policies using our specialized comparison
    cJSON_bool result = aws_policy_compare_items(policy_obj1, policy_obj2, 0);

    cJSON_Delete(policy_obj1);
    cJSON_Delete(policy_obj2);

    sqlite3_result_int(context, result);
}

#ifdef _WIN32
__declspec(dllexport)
#endif

int sqlite3_awspolicyequal_init(sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi) {
    SQLITE_EXTENSION_INIT2(pApi)
    sqlite3_create_function(db, "aws_policy_equal", 2, SQLITE_UTF8, NULL, aws_policy_equal, NULL, NULL);
    return SQLITE_OK;
}