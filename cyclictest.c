#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>

#define NSEC_PER_SEC 1000000000LL
#define USEC_PER_SEC 1000000LL

static inline void tsnorm(struct timespec *ts) {
    while (ts->tv_nsec >= NSEC_PER_SEC) {
        ts->tv_nsec -= NSEC_PER_SEC;
        ts->tv_sec++;
    }
}

static inline int64_t calcdiff_ns(struct timespec t1, struct timespec t2) {
    int64_t diff = NSEC_PER_SEC * (int64_t)((int) t1.tv_sec - (int) t2.tv_sec);
    diff += ((int) t1.tv_nsec - (int) t2.tv_nsec);
    return diff;
}

int main(int argc, char **argv) {
    struct timespec now, next, interval, sleep_time;
    int max_cycles = 60000;     
    int interval_us = 1000;      
    
    long min = 1000000;
    long max = 0;
    double avg = 0.0;

    if (argc > 1) max_cycles = atoi(argv[1]);
    if (argc > 2) interval_us = atoi(argv[2]);

    interval.tv_sec = interval_us / USEC_PER_SEC;
    interval.tv_nsec = (interval_us % USEC_PER_SEC) * 1000;

    long *latencies = (long *)malloc(max_cycles * sizeof(long));
    if (!latencies) {
        fprintf(stderr, "Memory allocation failed\n");
        return 1;
    }

    printf("# Interval: %d us | Loops: %d\n", interval_us, max_cycles);
    printf("# Cycle_Count Latency_us\n");

    clock_gettime(CLOCK_MONOTONIC, &now);
    next = now;
    next.tv_sec += interval.tv_sec;
    next.tv_nsec += interval.tv_nsec;
    tsnorm(&next);

    for (int i = 0; i < max_cycles; i++) {
        clock_gettime(CLOCK_MONOTONIC, &now);
        int64_t sleep_ns = calcdiff_ns(next, now);
        
        if (sleep_ns > 0) {
            sleep_time.tv_sec = sleep_ns / NSEC_PER_SEC;
            sleep_time.tv_nsec = sleep_ns % NSEC_PER_SEC;
            nanosleep(&sleep_time, NULL);
        }

        clock_gettime(CLOCK_MONOTONIC, &now);
        int64_t diff_ns = calcdiff_ns(now, next);
        long diff_us = diff_ns / 1000;

        latencies[i] = diff_us;

        if (diff_us < min) min = diff_us;
        if (diff_us > max) max = diff_us;
        avg += (double) diff_us;

        next.tv_sec += interval.tv_sec;
        next.tv_nsec += interval.tv_nsec;
        tsnorm(&next);
    }

    avg = avg / max_cycles;

    for (int i = 0; i < max_cycles; i++) {
        printf("%d %ld\n", i, latencies[i]);
    }

    printf("# T: 0 (%5d) I:%ld C:%7d Min:%7ld Avg:%5ld Max:%8ld\n",
           0, (long)interval_us, max_cycles, min, (long)avg, max);

    free(latencies);
    return 0;
}