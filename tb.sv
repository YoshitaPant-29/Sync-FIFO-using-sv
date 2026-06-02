module fifo_tb;

logic clk;
logic rst;

logic wr_en;
logic rd_en;

logic [7:0] data_in;
logic [7:0] data_out;

logic full;
logic empty;

// DUT
sync_fifo dut(
    .clk(clk),
    .rst(rst),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)
);

/////////////////////////////////////////////////////
// CLOCK GENERATION
/////////////////////////////////////////////////////

always #5 clk = ~clk;

/////////////////////////////////////////////////////
// SCOREBOARD
/////////////////////////////////////////////////////

// Reference FIFO model

byte model_q[$];
byte expected_data;

// Compare DUT output with reference model

always @(posedge clk)
begin

    if(wr_en && !full)
        model_q.push_back(data_in);

    if(rd_en && !empty)
    begin
        expected_data = model_q.pop_front();

        assert(data_out == expected_data)
        else
        begin
            $error("FIFO ORDER ERROR");
            $display("Expected = %0d Got = %0d",
                     expected_data, data_out);
        end
    end

end

/////////////////////////////////////////////////////
// FUNCTIONAL COVERAGE
/////////////////////////////////////////////////////

covergroup fifo_cg @(posedge clk);

    coverpoint wr_en;
    coverpoint rd_en;

    coverpoint full;
    coverpoint empty;

    // Read/Write combinations
    cross wr_en, rd_en;

    // Writing when FIFO is full
    cross full, wr_en;

    // Reading when FIFO is empty
    cross empty, rd_en;

endgroup

fifo_cg cg = new();

/////////////////////////////////////////////////////
// ASSERTIONS
/////////////////////////////////////////////////////

// FIFO must be empty after reset

assert property (@(posedge clk)
    rst |=> empty
);

// Write pointer must not move when full

assert property (@(posedge clk)
    (wr_en && full)
    |=> $stable(dut.wr_ptr)
);

// Read pointer must not move when empty

assert property (@(posedge clk)
    (rd_en && empty)
    |=> $stable(dut.rd_ptr)
);

// Simultaneous read/write keeps count unchanged

assert property (@(posedge clk)
    (wr_en && rd_en && !full && !empty)
    |=> dut.count == $past(dut.count)
);

/////////////////////////////////////////////////////
// STIMULUS
/////////////////////////////////////////////////////

initial
begin

    $dumpfile("dump.vcd");
    $dumpvars(0,fifo_tb);

    clk = 0;
    rst = 1;

    wr_en = 0;
    rd_en = 0;

    data_in = 0;

    //-------------------------
    // RESET
    //-------------------------

    #20;
    rst = 0;

    //-------------------------
    // TEST 1 : FILL FIFO
    //-------------------------

    $display("\nTEST 1 : Fill FIFO");

    repeat(8)
    begin
        @(posedge clk);

        wr_en = 1;
        rd_en = 0;

        data_in = $urandom_range(1,255);
    end

    @(posedge clk);
    wr_en = 0;

    //-------------------------
    // TEST 2 : WRITE WHEN FULL
    //-------------------------

    $display("\nTEST 2 : Write when Full");

    @(posedge clk);

    wr_en = 1;
    data_in = 8'hAA;

    @(posedge clk);

    wr_en = 0;

    //-------------------------
    // TEST 3 : EMPTY FIFO
    //-------------------------

    $display("\nTEST 3 : Empty FIFO");

    repeat(8)
    begin
        @(posedge clk);

        rd_en = 1;
        wr_en = 0;
    end

    @(posedge clk);
    rd_en = 0;

    //-------------------------
    // TEST 4 : READ WHEN EMPTY
    //-------------------------

    $display("\nTEST 4 : Read when Empty");

    @(posedge clk);

    rd_en = 1;

    @(posedge clk);

    rd_en = 0;

    //-------------------------
    // TEST 5 : SIMULTANEOUS
    //-------------------------

    $display("\nTEST 5 : Simultaneous Read/Write");

    repeat(5)
    begin

        @(posedge clk);

        wr_en   = 1;
        rd_en   = 1;
        data_in = $urandom_range(0,255);

    end

    @(posedge clk);

    wr_en = 0;
    rd_en = 0;

    //-------------------------
    // TEST 6 : RANDOM TESTING
    //-------------------------

    $display("\nTEST 6 : Random Testing");

    repeat(50)
    begin

        @(posedge clk);

        wr_en   = $urandom_range(0,1);
        rd_en   = $urandom_range(0,1);
        data_in = $urandom_range(0,255);

    end

    @(posedge clk);

    wr_en = 0;
    rd_en = 0;

    //-------------------------
    // COVERAGE REPORT
    //-------------------------

    $display("\nCoverage = %0.2f %%", cg.get_coverage());

    #20;

    $display("\nFIFO Verification Completed Successfully");

    $finish;

end

endmodule
