#include "snrt.h"

int main() {

    uint32_t start_cycle = snrt_mcycle();

    uint32_t end_cycle = snrt_mcycle();
    printf("Hello!\n");
    return 0;
}
