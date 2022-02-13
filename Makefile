CC=gcc
CXX=g++
RM=rm -f
CPPFLAGS=-g -Wall -I$(PWD)/inc -DDEBUG
LDFLAGS=-g

CPPUTEST_HOME = /home/ir-coaster-soft/tools/cpputest
CPPFLAGS += -I$(CPPUTEST_HOME)/include
LDLIBS = -L$(CPPUTEST_HOME)/lib -lCppUTest -lCppUTestExt -lpthread
DEBUGFLAGS = -Dprivate=public

SRCS=src/position_library.cpp src/libraries_mockup.cpp
MAIN_OBJS=$(subst .cpp,.o,$(SRCS)) main.o
TESTS_OBJS=$(subst .cpp,.o,$(SRCS)) tests.o

all: dead_reckoning tests

dead_reckoning: $(MAIN_OBJS)
	$(CXX) $(LDFLAGS) -o build/dead_reckoning $(MAIN_OBJS) $(LDLIBS)

tests: $(TESTS_OBJS)
	$(CXX) $(LDFLAGS) -o build/tests $(TESTS_OBJS) $(LDLIBS)
	./build/tests

depend: .depend

.depend: $(SRCS)
	$(RM) ./.depend
	$(CXX) $(CPPFLAGS) -MM $^>>./.depend;

clean:
	$(RM) $(TESTS_OBJS) $(MAIN_OBJS)

distclean: clean
	$(RM) *~ .depend

include .depend
