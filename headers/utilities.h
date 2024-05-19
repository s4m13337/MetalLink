/*
    Utility functions for MetalLink
*/
#ifndef UTILITIES_H
#define UTILITIES_H
#include <stdio.h>
#include<time.h>

void logToFile(char* message);
double measureTime(clock_t t_start, clock_t t_end);

#endif