#include "utilities.h"

void logToFile(char* message){
    time_t seconds;
    seconds = time(NULL);
    FILE *file = fopen("log", "a");
    if (file == NULL) { return; }
    fprintf(file, "[%ld] - %s\n", seconds, message);
    fclose(file);
}

double measureTime(clock_t t_start, clock_t t_end){
    return ((double)(t_end - t_start)) / CLOCKS_PER_SEC;
}