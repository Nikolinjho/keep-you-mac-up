#include <errno.h>
#include <poll.h>
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef KYA_REFRESH_MS
#define KYA_REFRESH_MS 1000
#endif

#ifdef KYA_LID_TESTING
static int set_lid_sleep_disabled(bool disabled)
{
    fprintf(stderr, "%s\n", disabled ? "disable" : "restore");
    const char *failure = getenv(disabled ? "KYA_TEST_FAIL_ENABLE" : "KYA_TEST_FAIL_RESTORE");
    return failure != NULL ? 1 : 0;
}
#else
#include <IOKit/IOKitLib.h>
#include <IOKit/pwr_mgt/IOPMLibDefs.h>

static int set_lid_sleep_disabled(bool disabled)
{
    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault,
                                                      IOServiceMatching("IOPMrootDomain"));
    if (service == IO_OBJECT_NULL) return kIOReturnNotFound;

    io_connect_t connection = IO_OBJECT_NULL;
    kern_return_t result = IOServiceOpen(service, mach_task_self(), 0, &connection);
    IOObjectRelease(service);
    if (result != KERN_SUCCESS) return result;

    // В SDK этот селектор есть, но Apple не документирует его как API приложения.
    uint64_t input = disabled ? 1 : 0;
    uint32_t output_count = 0;
    result = IOConnectCallScalarMethod(connection, kPMSetClamshellSleepState,
                                       &input, 1, NULL, &output_count);
    IOServiceClose(connection);
    return result;
}
#endif

static volatile sig_atomic_t stopping = 0;

static void stop(int signal_number)
{
    (void)signal_number;
    stopping = 1;
}

static int restore_lid_sleep(void)
{
    for (int attempt = 0; attempt < 3; attempt++) {
        int result = set_lid_sleep_disabled(false);
        if (result == 0) return 0;
        fprintf(stderr, "Cannot restore lid sleep: 0x%x\n", result);
        usleep(100000);
    }
    return 1;
}

int main(int argc, const char *argv[])
{
    if (argc == 2 && strcmp(argv[1], "--restore") == 0) return restore_lid_sleep();
    if (argc != 1) return 64;

    struct sigaction action = {0};
    action.sa_handler = stop;
    sigemptyset(&action.sa_mask);
    sigaction(SIGTERM, &action, NULL);
    sigaction(SIGINT, &action, NULL);
    sigaction(SIGHUP, &action, NULL);
    signal(SIGPIPE, SIG_IGN);

    int result = set_lid_sleep_disabled(true);
    if (result != 0) {
        fprintf(stderr, "Cannot disable lid sleep: 0x%x\n", result);
        restore_lid_sleep();
        return 1;
    }

    // Готовность подтверждаем только после успешного запроса к ядру.
    if (write(STDOUT_FILENO, "R", 1) != 1) return restore_lid_sleep();

    struct pollfd input = {.fd = STDIN_FILENO, .events = POLLIN | POLLHUP};
    int failed = 0;
    while (!stopping) {
        int events = poll(&input, 1, KYA_REFRESH_MS);
        if (events < 0) {
            if (errno == EINTR) continue;
            failed = 1;
            break;
        }
        if (events > 0) {
            char buffer[32];
            if (input.revents & (POLLERR | POLLNVAL)) { failed = 1; break; }
            ssize_t count = read(STDIN_FILENO, buffer, sizeof(buffer));
            if (count == 0) break;
            if (count < 0 && errno != EINTR) { failed = 1; break; }
        }
        if (!stopping && set_lid_sleep_disabled(true) != 0) { failed = 1; break; }
    }

    int restore_result = restore_lid_sleep();
    return failed || restore_result;
}
