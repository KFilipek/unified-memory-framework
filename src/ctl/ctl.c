#include "ctl.h"

#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_OPTIONS 100
#define MAX_STRING_LENGTH 256

int matrix_length = MAX_OPTIONS;
int string_length = MAX_STRING_LENGTH;

Option options[MAX_OPTIONS];

#ifdef _WIN32
#define strdup _strdup
#endif

void init() {
    ctlAddPath("ctl.log.enable=0", OPTION_TYPE_BOOL, OPERATION_TYPE_RW, NULL,
               NULL, NULL);
}

void ctlAddPath(const char *path, enum OptionType type,
                enum OperationType operation, void *(*read_cb)(void *),
                void *(*write_cb)(void *), void *(*exec_cb)(void *)) {
    // Sample path: debug.log.enable=1
    // Sample path: debug.log.level=5
    // Sample path: debug.log.path=/var/log/debug.log

    // Find the first '=', and replace it with '\0', then set value as the next character
    (void)operation;
    char *path_copy = strdup(path);

    void *value = NULL;
    char *equal_sign = strchr(path_copy, '=');
    if (equal_sign != NULL) {
        *equal_sign = '\0';
        value = equal_sign + 1;
    }
    for (int i = 0; i < MAX_OPTIONS; i++) {
        if (options[i].path == NULL) {
            options[i].path = strdup(path_copy);
            options[i].type = type;
            switch (type) {
            case OPTION_TYPE_STRING:
                options[i].value.string_value = strdup((char *)value);
                break;
            case OPTION_TYPE_INT:
                if (value != NULL) {
                    options[i].value.int_value = atoi((char *)value);
                }
                break;
            case OPTION_TYPE_BOOL:
                if (value != NULL) {
                    options[i].value.bool_value = atoi((char *)value);
                }
                break;
            case OPTION_TYPE_EXEC:
                break;
            }

            options[i].callback_r = read_cb;
            options[i].callback_w = write_cb;
            if (options[i].callback_w != NULL) {
                options[i].callback_w(value);
            }
            options[i].callback_exec = exec_cb;
            break;
        }
    }
    free(path_copy);
}

void printPaths() {
    for (int i = 0; i < MAX_OPTIONS; i++) {
        if (options[i].path != NULL) {
            if (*(int *)ctlExecutePath("ctl.log.enable", OPERATION_TYPE_RO) ==
                1) {
                printf("Path: %s, ", options[i].path);
            }
            switch (options[i].type) {
            case OPTION_TYPE_STRING:
                if (*(int *)ctlExecutePath("ctl.log.enable",
                                           OPERATION_TYPE_RO) == 1) {
                    printf("Value: %s\n", options[i].value.string_value);
                }
                break;
            case OPTION_TYPE_INT:
                if (*(int *)ctlExecutePath("ctl.log.enable",
                                           OPERATION_TYPE_RO) == 1) {
                    printf("Value: %d\n", options[i].value.int_value);
                }
                break;
            case OPTION_TYPE_BOOL:
                if (*(int *)ctlExecutePath("ctl.log.enable",
                                           OPERATION_TYPE_RO) == 1) {
                    printf("Value: %d\n", options[i].value.bool_value);
                }
                break;
            case OPTION_TYPE_EXEC:
                if (*(int *)ctlExecutePath("ctl.log.enable",
                                           OPERATION_TYPE_RO) == 1) {
                    printf("Callback\n");
                }
                break;
            }
        }
    }
}

int pathExists(const char *path) {
    for (int i = 0; i < MAX_OPTIONS; i++) {
        if (options[i].path != NULL && strcmp(options[i].path, path) == 0) {
            return 1;
        }
    }
    return 0;
}

int validate_path(const char *path) {
    int has_equal_sign = 0;
    int previous_was_dot = 0;
    if (*path == '.') {
        return 0; // First character cannot be a dot
    }
    while (*path) {
        if (*path == '.') {
            // Check if the previous character was also a dot
            if (previous_was_dot) {
                return 0; // Consecutive dots are not allowed
            }
            previous_was_dot = 1;
        } else {
            previous_was_dot = 0;
        }

        if (*path == '=') {
            // Check if this is the first equal sign and if the previous character was alphanumeric
            if (has_equal_sign || !isalnum(*(path - 1))) {
                return 0;
            }
            has_equal_sign = 1;
        }
        path++;
    }

    // Check if the last character was alphanumeric or an equal sign
    return isalnum(*(path - 1)) || (*(path - 1) == '=' && has_equal_sign);
}

void *ctlExecutePath(const char *path, enum OperationType operation) {
    if (!validate_path(path)) {
        return NULL;
    }
    char *path_copy = strdup(path);
    void *value = NULL;
    char *equal_sign = strchr(path_copy, '=');
    if (operation == OPERATION_TYPE_RW && equal_sign == NULL) {
        free(path_copy);
        return NULL;
    }
    if (equal_sign != NULL) {
        *equal_sign = '\0';
        value = equal_sign + 1;
    }
    for (int i = 0; i < MAX_OPTIONS; i++) {
        if (options[i].path != NULL &&
            strcmp(options[i].path, path_copy) == 0) {
            if (options[i].type == OPTION_TYPE_EXEC) {
                switch (operation) {
                case OPERATION_TYPE_RO:
                    if (options[i].callback_r != NULL) {
                        free(path_copy);
                        return options[i].callback_r(NULL);
                    }
                    break;
                case OPERATION_TYPE_RW:
                    if (options[i].callback_w != NULL) {
                        options[i].callback_w(value);
                        free(path_copy);
                        return value;
                    }
                    break;
                case OPERATION_TYPE_EXEC:
                    if (options[i].callback_exec != NULL) {
                        options[i].callback_exec(value);
                        free(path_copy);
                        return value;
                    }
                    break;
                case OPERATION_TYPE_CALLBACK:
                    break;
                }
            } else {
                switch (operation) {
                case OPERATION_TYPE_RO:
                    switch (options[i].type) {
                    case OPTION_TYPE_STRING:
                        free(path_copy);
                        return options[i].value.string_value;
                    case OPTION_TYPE_INT:
                        free(path_copy);
                        return &options[i].value.int_value;
                    case OPTION_TYPE_BOOL:
                        free(path_copy);
                        return &options[i].value.bool_value;
                    case OPTION_TYPE_EXEC:
                        free(path_copy);
                        return NULL;
                    }
                    break;
                case OPERATION_TYPE_RW:
                    switch (options[i].type) {
                    case OPTION_TYPE_STRING:
                        options[i].value.string_value = strdup((char *)value);
                        free(path_copy);
                        return options[i].value.string_value;
                    case OPTION_TYPE_INT:
                        if (value != NULL) {
                            options[i].value.int_value = atoi((char *)value);
                        }
                        free(path_copy);
                        return &options[i].value.int_value;
                    case OPTION_TYPE_BOOL:
                        if (value != NULL) {
                            options[i].value.bool_value = atoi((char *)value);
                        }
                        free(path_copy);
                        return &options[i].value.bool_value;
                    case OPTION_TYPE_EXEC:
                        free(path_copy);
                        return NULL;
                    }
                    break;
                case OPERATION_TYPE_EXEC:
                    free(path_copy);
                    return NULL;
                case OPERATION_TYPE_CALLBACK:
                    break;
                }
            }
        }
    }
    free(path_copy);
    return NULL;
}
