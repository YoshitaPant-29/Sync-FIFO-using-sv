module sync_fifo #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
)(
    input  logic clk,
    input  logic rst,

    input  logic wr_en,
    input  logic rd_en,

    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,

    output logic full,
    output logic empty
);

    // FIFO storage memory
    logic [WIDTH-1:0] mem [0:DEPTH-1];

    // Write and Read pointers
    logic [$clog2(DEPTH)-1:0] wr_ptr;
    logic [$clog2(DEPTH)-1:0] rd_ptr;

    // Number of occupied locations
    logic [$clog2(DEPTH+1)-1:0] count;

    // Status flags
    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    always_ff @(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            wr_ptr   <= 0;
            rd_ptr   <= 0;
            count    <= 0;
            data_out <= 0;
        end
        else
        begin

            //-------------------------
            // WRITE OPERATION
            //-------------------------
            if(wr_en && !full)
            begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= (wr_ptr + 1) % DEPTH;
            end

            //-------------------------
            // READ OPERATION
            //-------------------------
            if(rd_en && !empty)
            begin
                data_out <= mem[rd_ptr];
                rd_ptr <= (rd_ptr + 1) % DEPTH;
            end

            //-------------------------
            // UPDATE COUNT
            //-------------------------
            case({wr_en && !full, rd_en && !empty})

                2'b10: count <= count + 1; // write only

                2'b01: count <= count - 1; // read only

                2'b11: count <= count;     // simultaneous

                default: count <= count;

            endcase

        end
    end

endmodule
