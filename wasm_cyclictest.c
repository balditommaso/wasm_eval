#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>

#define NSEC_PER_SEC 1000000000L
#define USEC_PER_SEC 1000000L


static inline void tsnorm(struct timespec *ts)
{
    while (ts->tv_nsec >= NSEC_PER_SEC) {
        ts->tv_nsec -= NSEC_PER_SEC;
        ts->tv_sec++;
    }
}


static inline int64_t calcdiff_ns(struct timespec t1, struct timespec t2)
{
    int64_t diff = NSEC_PER_SEC * (int64_t)((int) t1.tv_sec - (int) t2.tv_sec);
    diff += ((int) t1.tv_nsec - (int) t2.tv_nsec);
    return diff;
}


int main(int argc, char **argv)
{
    struct timespec now, next, interval, sleep_time;
    int max_cycles = 10000;
    int interval_us = 1000; // 1 ms

    long min = 1000000;
    long max = 0;
    double avg = 0.0;
    long act = 0;

    // TODO
}