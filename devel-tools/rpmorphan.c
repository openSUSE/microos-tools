/*
 Copyright (c) 2019,2020 SUSE LLC
 Author: Adam Majer

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/

#include <rpm/rpmts.h>
#include <rpm/rpmdb.h>
#include <rpm/rpmlib.h>
#include <fcntl.h>
#include <rpm/rpmcli.h>
#include <rpm/header.h>
#include <rpm/rpmfiles.h>

#include <dirent.h>
#include <stdlib.h>
#include <string.h>

static int check_list(const char * const * known_list, size_t known_list_size, const char *p)
{
	int pos = known_list_size / 2;
	int top = known_list_size;
	int bot = 0;
	for (;;) {
		// fprintf(stderr, "checking vs: %s  @ %d\n", known_list[pos], pos);
		int c = strcmp(p, known_list[pos]);
		if (c == 0)
			return pos;

		if (c < 0)
			top = pos;
		if (c > 0) {
			if (bot == pos)
				break;
			bot = pos;
		}

		if (bot + (top - bot)/2 == pos)
			break;
		pos = bot + (top - bot)/2;
	}

	return -1;
}

static void scan_subdirs(const char *dir, const char * const * filters,
                        const char ** known_list, size_t known_list_size)
{
	char fullpath[10240];
	DIR *d = opendir(dir);
	if (d == NULL)
		return;

	struct dirent *e;
	while ((e = readdir(d)) != NULL) {
		if (strcmp(e->d_name, ".") == 0 || strcmp(e->d_name, "..") == 0)
			continue;

		switch (e->d_type) {
		case DT_DIR:
		case DT_LNK:
		case DT_REG:
		{
			if (strlen(dir) + strlen(e->d_name) + 2 > 10240)
				abort();

			strcpy(fullpath, dir);
			strcat(fullpath, "/");
			strcat(fullpath, e->d_name);

			if (check_list(known_list, known_list_size, fullpath) == -1) {
				puts(fullpath);
			}

			if (e->d_type == DT_DIR) {
				const char * const *f = filters;
				while (*f != NULL && strcmp(*f, fullpath) != 0) f++;
				if (*f == NULL)
					scan_subdirs(fullpath, filters, known_list, known_list_size);
			}
		}
		}
	}
	closedir(d);
}

static int str_sort(const void *a, const void *b)
{
	return strcmp(*(const char**)a, *(const char**)b);
}

int main()
{
	rpmcliConfigured();
	rpmts dbts = rpmtsCreate();
	if (!dbts) {
		printf("ERROR\n:");
		return -1;
	}


	if (rpmtsOpenDB(dbts, O_RDONLY) != 0) {
		printf("BAD BAD\n");
		return -3;
	}

	size_t paths_size = 1024 * 128, count = 0;
	char **known_paths = malloc(sizeof(char*) * paths_size);

	rpmdbMatchIterator iter = rpmtsInitIterator(dbts, RPMDBI_PACKAGES, NULL, 0);
	Header hdr;
	while ((hdr = rpmdbNextIterator(iter)) != NULL) {
		rpmfiles files = rpmfilesNew(NULL, hdr, 0, 0);
		rpmfi fi = rpmfilesIter(files, 0);
		while (rpmfiNext(fi) >= 0) {
			if (count >= paths_size) {
				paths_size *= 2;
				known_paths = realloc(known_paths, sizeof(char*) * paths_size);
			}
			known_paths[count++] = strdup(rpmfiFN(fi));
		}
		rpmfiFree(fi);
		rpmfilesFree(files);
	}


	// sort the known list
	qsort(known_paths, count, sizeof(char*), str_sort);

	// Iterate over /usr (!/usr/local) and /lib, /lib64, /sbin
	// and find things not in the database
	const char *dirs[] = { "/usr", "/lib", "/lib64", "/sbin", NULL };
	const char *filter_dirs[] = { "/usr/local", NULL };

	for (const char * const * dir = dirs; *dir != NULL; ++dir)
		scan_subdirs(*dir, filter_dirs, (const char**)known_paths, count);

	return 0;
}

