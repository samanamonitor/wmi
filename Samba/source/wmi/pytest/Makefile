
CFLAGS=-I/usr/include -I/usr/include/python3.6m -DNDEBUG -g -O3 -Wall -Wstrict-prototypes -fPIC -DMAJOR_VERSION=1 -DMINOR_VERSION=0


%.so: %.o
	$(CC) -shared $^ -L/usr/lib -o $@