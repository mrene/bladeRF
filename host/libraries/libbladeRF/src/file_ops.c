/*
 * This file is part of the bladeRF project:
 *   http://www.github.com/nuand/bladeRF
 *
 * Copyright (C) 2013 Nuand LLC
 * Copyright (C) 2013 Daniel Gröber <dxld ÄT darkboxed DOT org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>
#include <errno.h>
#include <libbladeRF.h>
#include "host_config.h"
#include "file_ops.h"
#include "log.h"

int file_write(FILE *f, uint8_t *buf, size_t len)
{
    size_t rv;

    rv = fwrite(buf, 1, len, f);
    if(rv < len) {
        log_debug("File write failed: %s\n", strerror(errno));
        return BLADERF_ERR_IO;
    }

    return 0;
}

int file_read(FILE *f, char *buf, size_t len)
{
    size_t rv;

    rv = fread(buf, 1, len, f);
    if(rv < len) {
        if(feof(f))
            log_debug("Unexpected end of file: %s\n", strerror(errno));
        else
            log_debug("Error reading file: %s\n", strerror(errno));

        return BLADERF_ERR_IO;
    }

    return 0;
}

ssize_t file_size(FILE *f)
{
    ssize_t rv = BLADERF_ERR_IO;
    long int fpos = ftell(f);
    ssize_t len;

    if(fpos < 0) {
        log_verbose("ftell failed: %s\n", strerror(errno));
        goto out;
    }

    if(fseek(f, 0, SEEK_END)) {
        log_verbose("fseek failed: %s\n", strerror(errno));
        goto out;
    }

    len = ftell(f);
    if(len < 0) {
        log_verbose("ftell failed: %s\n", strerror(errno));
        goto out;
    }

    if(fseek(f, fpos, SEEK_SET)) {
        log_debug("fseek failed: %s\n", strerror(errno));
        goto out;
    }

    rv = len;

out:
    return rv;
}

int file_read_buffer(const char *filename, uint8_t **buf_ret, size_t *size_ret)
{
    int status = BLADERF_ERR_UNEXPECTED;
    FILE *f;
    uint8_t *buf = NULL;
    ssize_t len;

    f = fopen(filename, "rb");
    if (!f) {
        int errno_val = errno;
        log_verbose("fopen failed: %s\n", strerror(errno));
        return errno_val == ENOENT ? BLADERF_ERR_NO_FILE : BLADERF_ERR_IO;
    }

    len = file_size(f);
    if(len < 0) {
        status = BLADERF_ERR_IO;
        goto out;
    }

    buf = malloc(len);
    if (!buf) {
        status = BLADERF_ERR_MEM;
        goto out;
    }

    status = file_read(f, (char*)buf, len);
    if (status < 0) {
        goto out;
    }

    *buf_ret = buf;
    *size_ret = len;
    fclose(f);
    return 0;

out:
    free(buf);
    if (f) {
        fclose(f);
    }

    return status;
}
