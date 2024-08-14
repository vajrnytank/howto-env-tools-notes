//Implementation of a simple Single-Producer-Single-Consumer queue
#include <vector>
#include <optional>
#include <iostream>
#include <thread>
#include <condition_variable>
#include <mutex>
#include <ctime>

std::mutex mtx;
std::condition_variable cv;

using namespace std::this_thread;
using namespace std::chrono_literals;
using std::chrono::system_clock;

template <typename T>

class SPSCQueue
{
private:
    std::vector<T> buffer = std::vector<T>();
    int head;
    int tail;
    int capacity;
    int mask;
    bool ready= false;
public:
    SPSCQueue() {
        capacity = 1048576; //2^20
        mask = --capacity;
        head = 0;
        tail = 0;
        buffer.resize(capacity);
    }

    bool push(const T& v) {
        std::unique_lock<std::mutex> lck(mtx);
        if (full()) {
            ready = true;
            cv.notify_one();
            cv.wait(lck);
        }
        buffer[head] = v;
        head = (++head) & mask;
        return true;
    }

    std::optional<T> pop() {
        if (!ready) {
            sleep_for(10ns);
            ready = true;
        }

        while (empty()) {
            ready = false;
            cv.notify_one();
            sleep_for(10ns);
        }  

        T show = buffer[tail];
        tail = (++tail) & mask;
        return show;
    }
    
    bool full() const { return ((head + 1) & mask) == tail; }

    bool empty() const { return head == tail; }
    
};


