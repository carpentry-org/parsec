#ifndef CARP_PARSEC_FFI_H
#define CARP_PARSEC_FFI_H

#include <string.h>

bool Parser_substr_MINUS_eq_QMARK_(String *src, int pos, String *s, int slen) {
    return memcmp(*src + pos, *s, (size_t)slen) == 0;
}

#endif
