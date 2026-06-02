# Sync-FIFO-using-sv

### A synchronous FIFO is a First-In-First-Out memory buffer where both read and write operations are controlled by the same clock. It is used to temporarily store data while maintaining the order of arrival. The design typically consists of a memory array, read and write pointers, occupancy counter, and full/empty status flags. Synchronous FIFOs are commonly used for buffering and flow control between digital modules operating in the same clock domain.
### A synchronous FIFO acts like a queue that stores data temporarily and ensures that the first data written is the first data read while both operations use the same clock.
This project demonstrates:

RTL FIFO design using pointers and count.
Queue-based scoreboard for data integrity.
Assertions for reset, full, empty, and simultaneous operations.
Functional coverage with covergroups and cross coverage.
Directed testing (fill, empty, full, empty-read).
Random testing for broader scenario exploration.

Applications
UART communication – stores received data before the CPU reads it.
Processor pipelines – buffers instructions/data between stages.
Network routers – stores packets before forwarding.
Camera/Sensor systems – buffers incoming data streams.
FPGA designs – transfers data safely between modules.

###UNDERSTANDING

Assertion 1
FIFO should be empty after reset
assert property (@(posedge clk)
    rst |=> empty
);

Meaning:

If reset occurs
then next cycle
empty must be 1
Assertion 2
Cannot read from empty FIFO
assert property (@(posedge clk)

    (rd_en && empty)

    |=> $stable(dut.rd_ptr)

);

Meaning:

Read requested
while FIFO empty

Read pointer must NOT move
Assertion 3
Cannot write into full FIFO
assert property (@(posedge clk)

    (wr_en && full)

    |=> $stable(dut.wr_ptr)

);

Meaning:

Write requested
while FIFO full

Write pointer must NOT move
Assertion 4
Simultaneous Read + Write
assert property (@(posedge clk)

    (wr_en && rd_en && !full && !empty)

    |=> dut.count == $past(dut.count)

);

Meaning:

One item enters
One item leaves

Occupancy remains unchanged

Example:

Before = 5 items

Write + Read same cycle

After = 5 items
Coverage

Coverage answers:

Did I actually test all scenarios?
covergroup fifo_cg @(posedge clk);

    coverpoint wr_en;
    coverpoint rd_en;

    coverpoint full;
    coverpoint empty;

    cross wr_en, rd_en;

    cross full, wr_en;

    cross empty, rd_en;

endgroup
Coverpoint
coverpoint wr_en;

Checks:

Did wr_en become 0?
Did wr_en become 1?
Cross Coverage
cross full, wr_en;

Checks:

full=0 wr_en=0

full=0 wr_en=1

full=1 wr_en=0

full=1 wr_en=1

This specifically verifies:

Did I test writing when FIFO was full?
